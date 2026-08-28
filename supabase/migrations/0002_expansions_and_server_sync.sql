-- Erweiterungen (Expansions) als genestete Kindelemente ihres Basisspiels,
-- damit beim Verkaufen das gesamte gebundene Kapital (Basisspiel + eigene
-- Erweiterungen) sichtbar ist.

alter table public.games
  add column if not exists subtype text not null default 'boardgame'
    check (subtype in ('boardgame', 'boardgameexpansion')),
  add column if not exists expansion_of_game_id uuid
    references public.games (id) on delete set null;

create index if not exists games_expansion_of_game_id_idx
  on public.games (expansion_of_game_id);
