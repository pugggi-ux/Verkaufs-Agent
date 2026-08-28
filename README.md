# Verkaufs-Agent

BGG Sell/Keep Decision App — synchronisiert Denis' BoardGameGeek-Sammlung und hilft
per Tinder-artigem Swipe-Interface bei der Entscheidung, welche Spiele behalten oder
verkauft werden sollen. Für Spiele im Verkaufsstatus begleitet die App den kompletten
Prozess bis zum fertigen Kleinanzeigen-Inserat: Preisfindung, To-Do-Liste,
Verkaufstext-Baustein und Inserat-Laufzeit-Tracking.

Die vollständige fachliche Spezifikation steht in [`SPEC_v1.md`](./SPEC_v1.md).

## Tech-Stack

- **Flutter** (Web, Android, iOS) — `lib/`
- **Supabase** (Auth, Postgres, Edge Functions) — Schema in `supabase/migrations/`,
  serverseitiger BGG-Sync in `supabase/functions/bgg-sync/`

## Setup

### 1. Supabase-Projekt

1. Neues Projekt auf [supabase.com](https://supabase.com) anlegen.
2. Im SQL-Editor nacheinander `supabase/migrations/0001_init.sql` und
   `supabase/migrations/0002_expansions_and_server_sync.sql` ausführen
   (legt Tabellen `games`, `todos`, `listings`, `settings` inkl.
   Row-Level-Security sowie die Erweiterungs-Verschachtelung an).
3. Unter *Authentication → Providers* bleibt „Email“ aktiv (Standard) — die App
   nutzt einfaches E-Mail/Passwort-Login.
4. Unter *Project Settings → API* die **Project URL** und den **anon public key**
   kopieren.

### 2. BGG-Zugangsdaten

Seit Ende Oktober 2025 verlangt BGG für die XML-API (auch für die eigene
Sammlung) einen registrierten Authorization-Token. Registrierung unter
[boardgamegeek.com/using_the_xml_api](https://boardgamegeek.com/using_the_xml_api).
Für den automatischen Import von `pricepaid` (Kaufpreis) wird zusätzlich eine
eingeloggte BGG-Session benötigt — dafür Benutzername + Passwort.

Diese drei Werte werden **nicht** in der App/`app.env` hinterlegt, sondern als
Secrets der Edge Function (siehe Schritt 3) — so verlassen Passwort und Token
nie den Server, insbesondere nicht das öffentlich ausgelieferte Web-Bundle.

### 3. BGG-Sync-Function deployen

```bash
# einmalig: Supabase CLI installieren, dann einloggen und Projekt verknüpfen
supabase login
supabase link --project-ref <dein-projekt-ref>

# Secrets setzen (Werte aus Schritt 2)
supabase secrets set BGG_USERNAME=dein-bgg-username \
  BGG_PASSWORD=dein-bgg-passwort \
  BGG_API_TOKEN=dein-bgg-api-token

# Function deployen
supabase functions deploy bgg-sync
```

Ohne `BGG_PASSWORD` funktioniert der Sync trotzdem (Name/Cover/Status), nur
`pricepaid` bleibt dann leer und muss manuell gepflegt werden.

### 4. Flutter-App konfigurieren

```bash
cp app.env.example app.env
# app.env mit den Werten aus Schritt 1 befüllen (nur Supabase URL + anon key)
```

Der Dateiname `app.env` (statt `.env`) ist bewusst gewählt: viele Static-Hoster
(z.B. Netlify) schließen versteckte Dateien (die mit `.` beginnen) standardmäßig
vom Deploy aus – als Flutter-Web-Asset ausgeliefert würde eine `.env`-Datei dort
sonst mit 404 fehlen und die App bliebe beim Start hängen.

### 5. Abhängigkeiten installieren & starten

```bash
flutter pub get
flutter run -d chrome     # Web
flutter run                # Android/iOS-Gerät bzw. Emulator
```

### 6. Web-Release-Build

```bash
flutter build web --release
```

## Projektstruktur

```
lib/
  models/        Datenmodelle (Game, Todo, Listing, AppSettings)
  services/       Supabase-Repositories, BGG-Sync, Todo-/Verkaufstext-Generatoren
  providers/      App-weiter State (Auth, Spieldaten) via provider-Paket
  screens/        Swipe-, Sammlung-, Detail-, Einstellungen-Screen
  widgets/        SwipeCard, PriceRangeBar, TodoChecklist
supabase/
  migrations/     SQL-Schema inkl. RLS-Policies
  functions/
    bgg-sync/     Edge Function: BGG-Login + Collection-Sync (Deno)
```

## Kernfunktionen (siehe SPEC_v1.md)

1. **BGG-Sync** — serverseitiger Collection-Import per XMLAPI2 (Name, Cover,
   `pricepaid`, Kaufdatum), inkl. Erweiterungen, die ihrem Basisspiel
   zugeordnet und in der Sammlung-Ansicht genestet dargestellt werden
   (gebundenes Kapital = Kaufpreis Basisspiel + eigene Erweiterungen)
2. **Swipe-Entscheidung** — Behalten / Verkaufen / Später entscheiden
   (nur Basisspiele; Erweiterungen übernehmen automatisch den Status ihres
   Basisspiels)
3. **Marktwert-Einschätzung** — manuelle Recherche-Range + Schmerzgrenze-Visualisierung
4. **To-Do-System** — automatisch generierte Checkliste pro Inserat
5. **Verkaufstext-Baustein** — editierbare Vorlage mit Ein-Klick-Kopie
6. **Inserat-Tracking** — Ablaufberechnung (+60 Tage) und Erinnerung

Bewusst nicht umgesetzt: automatischer Marktwert über externe APIs sowie
automatisches Erstellen/Auslesen von Kleinanzeigen-Inseraten (siehe Begründung
in `SPEC_v1.md`).
