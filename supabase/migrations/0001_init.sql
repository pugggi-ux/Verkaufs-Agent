-- Verkaufs-Agent: initiales Schema
-- Ausführen im Supabase SQL-Editor oder via `supabase db push`

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- games: importierte BGG-Sammlung + Verkaufsentscheidung + Marktwert
-- ---------------------------------------------------------------------
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  bgg_id integer not null,
  name text not null,
  cover_image_url text,
  kaufpreis numeric(10, 2),
  kaufdatum date,
  status text not null default 'unentschieden'
    check (status in ('unentschieden', 'behalten', 'verkaufen', 'verkauft')),
  recherche_min numeric(10, 2),
  recherche_max numeric(10, 2),
  recherche_datum timestamptz,
  schmerzgrenze_prozent_override numeric(5, 2),
  angebotspreis numeric(10, 2),
  zustand text,
  verkaufstext text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, bgg_id)
);

create index if not exists games_user_id_idx on public.games (user_id);
create index if not exists games_status_idx on public.games (status);

-- ---------------------------------------------------------------------
-- todos: pro Spiel generierte, individuell abhakbare Checkliste
-- ---------------------------------------------------------------------
create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id uuid not null references public.games (id) on delete cascade,
  key text not null,
  label text not null,
  done boolean not null default false,
  created_at timestamptz not null default now(),
  unique (game_id, key)
);

create index if not exists todos_game_id_idx on public.todos (game_id);

-- ---------------------------------------------------------------------
-- listings: Inserat-Tracking (Datum, Ablauf, Status)
-- ---------------------------------------------------------------------
create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id uuid not null references public.games (id) on delete cascade,
  inserat_datum date not null,
  ablaufdatum date generated always as (inserat_datum + interval '60 days') stored,
  status text not null default 'online'
    check (status in ('online', 'reserviert', 'verkauft', 'versendet')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists listings_game_id_idx on public.listings (game_id);

-- ---------------------------------------------------------------------
-- settings: eine Zeile pro Nutzer, globale Defaults + Textbausteine
-- ---------------------------------------------------------------------
create table if not exists public.settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  schmerzgrenze_prozent_default numeric(5, 2) not null default 65,
  recherche_intervall_tage integer not null default 90,
  erinnerung_tage_vor_ablauf integer not null default 8,
  bgg_username text,
  verkaufstext_vorlage text not null default
    'Zum Verkauf: {spielname}' || chr(10) ||
    'Zustand: {zustand}' || chr(10) ||
    'Preis: {angebotspreis} EUR',
  zahlungsmethoden text not null default 'Barzahlung bei Abholung oder PayPal (Freunde) im Voraus.',
  versandmodalitaeten text not null default 'Versand gegen Aufpreis (Kosten trägt der Käufer) oder Abholung möglich.',
  gewaehrleistungsausschluss text not null default
    'Privatverkauf, daher keine Garantie, Gewährleistung oder Rücknahme.',
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- updated_at automatisch pflegen
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists games_set_updated_at on public.games;
create trigger games_set_updated_at
  before update on public.games
  for each row execute function public.set_updated_at();

drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at
  before update on public.listings
  for each row execute function public.set_updated_at();

drop trigger if exists settings_set_updated_at on public.settings;
create trigger settings_set_updated_at
  before update on public.settings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- Row Level Security: jeder Nutzer sieht/ändert nur seine eigenen Daten
-- ---------------------------------------------------------------------
alter table public.games enable row level security;
alter table public.todos enable row level security;
alter table public.listings enable row level security;
alter table public.settings enable row level security;

create policy "games_owner" on public.games
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "todos_owner" on public.todos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "listings_owner" on public.listings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "settings_owner" on public.settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Beim Anlegen eines neuen Users automatisch eine Settings-Zeile erstellen
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
