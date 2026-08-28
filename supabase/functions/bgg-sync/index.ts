// Supabase Edge Function: bgg-sync
//
// Synchronisiert die eigene BGG-Sammlung (Basisspiele + Erweiterungen,
// jeweils nur status "own") inklusive privater Felder wie `pricepaid`.
//
// Läuft serverseitig, weil:
// 1. BGG verlangt seit Ende Oktober 2025 einen registrierten Bearer-Token
//    für die XML-API (auch für die eigene Sammlung).
// 2. `pricepaid`/`acquisitiondate` (privateinfo) werden nur ausgeliefert,
//    wenn die Anfrage zusätzlich mit einer eingeloggten BGG-Session-Cookie
//    erfolgt – das erfordert Benutzername+Passwort, die hier als
//    Edge-Function-Secrets liegen und niemals an den Client gehen.
// 3. Eine Browser-App könnte diese Login-Cookie wegen CORS ohnehin nicht
//    selbst setzen.
//
// Benötigte Secrets (supabase secrets set ...):
//   BGG_USERNAME, BGG_PASSWORD, BGG_API_TOKEN

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { XMLParser } from 'https://esm.sh/fast-xml-parser@4.5.0';

const BGG_LOGIN_URL = 'https://boardgamegeek.com/login/api/v1';
const BGG_COLLECTION_URL = 'https://boardgamegeek.com/xmlapi2/collection';
const BGG_THING_URL = 'https://boardgamegeek.com/xmlapi2/thing';

const xmlParser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '@_' });

function corsHeaders(origin: string | null) {
  return {
    'Access-Control-Allow-Origin': origin ?? '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  };
}

function asArray<T>(value: T | T[] | undefined): T[] {
  if (value === undefined) return [];
  return Array.isArray(value) ? value : [value];
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function bggLogin(username: string, password: string): Promise<string | null> {
  try {
    const res = await fetch(BGG_LOGIN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ credentials: { username, password } }),
    });
    if (!res.ok) {
      console.error(`BGG-Login fehlgeschlagen: HTTP ${res.status}`);
      return null;
    }
    const setCookies = (res.headers as unknown as { getSetCookie?: () => string[] }).getSetCookie?.() ?? [];
    if (setCookies.length === 0) {
      console.error('BGG-Login lieferte keine Session-Cookie.');
      return null;
    }
    return setCookies.map((c) => c.split(';')[0]).join('; ');
  } catch (e) {
    console.error('BGG-Login-Fehler:', e);
    return null;
  }
}

async function fetchCollectionXml(
  username: string,
  subtype: 'boardgame' | 'boardgameexpansion',
  apiToken: string,
  cookie: string | null,
): Promise<string> {
  const url =
    `${BGG_COLLECTION_URL}?username=${encodeURIComponent(username)}` +
    `&own=1&stats=1&showprivate=1&subtype=${subtype}`;
  const headers: Record<string, string> = { Authorization: `Bearer ${apiToken}` };
  if (cookie) headers['Cookie'] = cookie;

  for (let attempt = 0; attempt < 8; attempt++) {
    const res = await fetch(url, { headers });
    if (res.status === 200) return await res.text();
    if (res.status === 202) {
      await sleep(3000);
      continue;
    }
    throw new Error(`BGG-Collection-Abruf fehlgeschlagen (HTTP ${res.status}, subtype=${subtype}).`);
  }
  throw new Error(`BGG-Collection-Abruf: Timeout nach mehreren Versuchen (subtype=${subtype}).`);
}

interface ParsedItem {
  bggId: number;
  name: string;
  imageUrl: string | null;
  pricePaid: number | null;
  acquisitionDate: string | null;
  subtype: 'boardgame' | 'boardgameexpansion';
}

function parseCollection(xml: string, subtype: 'boardgame' | 'boardgameexpansion'): ParsedItem[] {
  const doc = xmlParser.parse(xml);
  const items = asArray(doc?.items?.item);
  const result: ParsedItem[] = [];

  for (const item of items) {
    const bggId = Number(item['@_objectid']);
    if (!bggId) continue;
    const nameRaw = item.name;
    const name = typeof nameRaw === 'object' ? String(nameRaw?.['#text'] ?? 'Unbekanntes Spiel') : String(nameRaw ?? 'Unbekanntes Spiel');
    const imageUrl = typeof item.image === 'string' ? item.image : null;

    let pricePaid: number | null = null;
    let acquisitionDate: string | null = null;
    const privateInfo = item.privateinfo;
    if (privateInfo) {
      const priceStr = privateInfo['@_pricepaid'];
      if (priceStr !== undefined && priceStr !== '') {
        const parsed = Number(priceStr);
        pricePaid = Number.isFinite(parsed) ? parsed : null;
      }
      const acqStr = privateInfo['@_acquisitiondate'];
      if (acqStr) acquisitionDate = String(acqStr);
    }

    result.push({ bggId, name, imageUrl, pricePaid, acquisitionDate, subtype });
  }
  return result;
}

async function fetchExpansionParents(
  bggIds: number[],
  apiToken: string,
): Promise<Map<number, number>> {
  const parentByExpansionId = new Map<number, number>();
  const chunkSize = 20;

  for (let i = 0; i < bggIds.length; i += chunkSize) {
    const chunk = bggIds.slice(i, i + chunkSize);
    const url = `${BGG_THING_URL}?id=${chunk.join(',')}`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${apiToken}` } });
    if (!res.ok) continue;
    const xml = await res.text();
    const doc = xmlParser.parse(xml);
    const items = asArray(doc?.items?.item);
    for (const item of items) {
      const expansionId = Number(item['@_id']);
      const links = asArray(item.link);
      const inboundExpansionLink = links.find(
        (l: Record<string, unknown>) =>
          l['@_type'] === 'boardgameexpansion' && l['@_inbound'] === 'true',
      );
      if (inboundExpansionLink) {
        const parentId = Number((inboundExpansionLink as Record<string, unknown>)['@_id']);
        if (parentId) parentByExpansionId.set(expansionId, parentId);
      }
    }
  }
  return parentByExpansionId;
}

Deno.serve(async (req) => {
  const origin = req.headers.get('origin');
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders(origin) });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Nicht authentifiziert.' }), {
        status: 401,
        headers: corsHeaders(origin),
      });
    }

    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: 'Ungültige Sitzung.' }), {
        status: 401,
        headers: corsHeaders(origin),
      });
    }
    const userId = userData.user.id;

    const bggUsername = Deno.env.get('BGG_USERNAME');
    const bggPassword = Deno.env.get('BGG_PASSWORD');
    const bggApiToken = Deno.env.get('BGG_API_TOKEN');
    if (!bggUsername || !bggApiToken) {
      return new Response(
        JSON.stringify({ error: 'BGG_USERNAME/BGG_API_TOKEN sind nicht als Secrets gesetzt.' }),
        { status: 500, headers: corsHeaders(origin) },
      );
    }

    let cookie: string | null = null;
    let privateInfoVerfuegbar = false;
    if (bggPassword) {
      cookie = await bggLogin(bggUsername, bggPassword);
      privateInfoVerfuegbar = cookie !== null;
    }

    const [baseGamesXml, expansionsXml] = await Promise.all([
      fetchCollectionXml(bggUsername, 'boardgame', bggApiToken, cookie),
      fetchCollectionXml(bggUsername, 'boardgameexpansion', bggApiToken, cookie),
    ]);

    const baseGames = parseCollection(baseGamesXml, 'boardgame');
    const expansions = parseCollection(expansionsXml, 'boardgameexpansion');
    const allItems = [...baseGames, ...expansions];

    const parentByExpansionId = expansions.length
      ? await fetchExpansionParents(expansions.map((e) => e.bggId), bggApiToken)
      : new Map<number, number>();

    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: existingRows, error: existingError } = await admin
      .from('games')
      .select('id, bgg_id, kaufpreis, kaufdatum')
      .eq('user_id', userId);
    if (existingError) throw existingError;

    const existingByBggId = new Map<number, { id: string; kaufpreis: number | null; kaufdatum: string | null }>();
    for (const row of existingRows ?? []) {
      existingByBggId.set(row.bgg_id as number, {
        id: row.id as string,
        kaufpreis: row.kaufpreis as number | null,
        kaufdatum: row.kaufdatum as string | null,
      });
    }

    let neu = 0;
    const bggIdToLocalId = new Map<number, string>(
      [...existingByBggId.entries()].map(([bggId, row]) => [bggId, row.id]),
    );

    for (const item of allItems) {
      const existing = existingByBggId.get(item.bggId);
      const acquisitionDateOnly = item.acquisitionDate ? item.acquisitionDate.substring(0, 10) : null;

      if (!existing) {
        const { data: inserted, error: insertError } = await admin
          .from('games')
          .insert({
            user_id: userId,
            bgg_id: item.bggId,
            name: item.name,
            cover_image_url: item.imageUrl,
            kaufpreis: item.pricePaid,
            kaufdatum: acquisitionDateOnly,
            subtype: item.subtype,
          })
          .select('id')
          .single();
        if (insertError) throw insertError;
        bggIdToLocalId.set(item.bggId, inserted.id as string);
        neu++;
      } else {
        const update: Record<string, unknown> = {
          name: item.name,
          cover_image_url: item.imageUrl,
          subtype: item.subtype,
        };
        if (existing.kaufpreis === null && item.pricePaid !== null) {
          update.kaufpreis = item.pricePaid;
        }
        if (existing.kaufdatum === null && acquisitionDateOnly) {
          update.kaufdatum = acquisitionDateOnly;
        }
        const { error: updateError } = await admin.from('games').update(update).eq('id', existing.id);
        if (updateError) throw updateError;
      }
    }

    let verknuepft = 0;
    for (const [expansionBggId, parentBggId] of parentByExpansionId.entries()) {
      const expansionLocalId = bggIdToLocalId.get(expansionBggId);
      const parentLocalId = bggIdToLocalId.get(parentBggId);
      if (!expansionLocalId || !parentLocalId) continue;
      const { error: linkError } = await admin
        .from('games')
        .update({ expansion_of_game_id: parentLocalId })
        .eq('id', expansionLocalId);
      if (linkError) throw linkError;
      verknuepft++;
    }

    return new Response(
      JSON.stringify({
        neu,
        gesamt: allItems.length,
        basisspiele: baseGames.length,
        erweiterungen: expansions.length,
        erweiterungenVerknuepft: verknuepft,
        privateInfoVerfuegbar,
      }),
      { status: 200, headers: corsHeaders(origin) },
    );
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e instanceof Error ? e.message : e) }), {
      status: 500,
      headers: corsHeaders(origin),
    });
  }
});
