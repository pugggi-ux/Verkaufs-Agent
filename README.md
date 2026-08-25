# Verkaufs-Agent

BGG Sell/Keep Decision App — synchronisiert Denis' BoardGameGeek-Sammlung und hilft
per Tinder-artigem Swipe-Interface bei der Entscheidung, welche Spiele behalten oder
verkauft werden sollen. Für Spiele im Verkaufsstatus begleitet die App den kompletten
Prozess bis zum fertigen Kleinanzeigen-Inserat: Preisfindung, To-Do-Liste,
Verkaufstext-Baustein und Inserat-Laufzeit-Tracking.

Die vollständige fachliche Spezifikation steht in [`SPEC_v1.md`](./SPEC_v1.md).

## Tech-Stack

- **Flutter** (Web, Android, iOS) — `lib/`
- **Supabase** (Auth, Postgres, Storage) — Schema in `supabase/migrations/0001_init.sql`

## Setup

### 1. Supabase-Projekt

1. Neues Projekt auf [supabase.com](https://supabase.com) anlegen.
2. Im SQL-Editor den Inhalt von `supabase/migrations/0001_init.sql` ausführen
   (legt Tabellen `games`, `todos`, `listings`, `settings` inkl. Row-Level-Security an).
3. Unter *Authentication → Providers* bleibt „Email“ aktiv (Standard) — die App
   nutzt einfaches E-Mail/Passwort-Login.
4. Unter *Project Settings → API* die **Project URL** und den **anon public key**
   kopieren.

### 2. Flutter-App konfigurieren

```bash
cp .env.example .env
# .env mit den Werten aus Schritt 1 sowie dem eigenen BGG-Benutzernamen befüllen
```

### 3. Abhängigkeiten installieren & starten

```bash
flutter pub get
flutter run -d chrome     # Web
flutter run                # Android/iOS-Gerät bzw. Emulator
```

### 4. Web-Release-Build

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
```

## Kernfunktionen (siehe SPEC_v1.md)

1. **BGG-Sync** — Collection-Import per XMLAPI2 (Name, Cover, `pricepaid`, Kaufdatum)
2. **Swipe-Entscheidung** — Behalten / Verkaufen / Später entscheiden
3. **Marktwert-Einschätzung** — manuelle Recherche-Range + Schmerzgrenze-Visualisierung
4. **To-Do-System** — automatisch generierte Checkliste pro Inserat
5. **Verkaufstext-Baustein** — editierbare Vorlage mit Ein-Klick-Kopie
6. **Inserat-Tracking** — Ablaufberechnung (+60 Tage) und Erinnerung

Bewusst nicht umgesetzt: automatischer Marktwert über externe APIs sowie
automatisches Erstellen/Auslesen von Kleinanzeigen-Inseraten (siehe Begründung
in `SPEC_v1.md`).
