# SPEC v1 – BGG Sell/Keep Decision App

## Ziel
Eine App, die Denis' BGG-Sammlung synchronisiert und ihm per Tinder-artigem Swipe-Interface hilft zu entscheiden, welche Spiele er behalten oder verkaufen möchte. Für Spiele, die verkauft werden sollen, verschlankt die App den kompletten Prozess bis zum fertigen Kleinanzeigen-Inserat: Preisfindung über eine selbst recherchierte Preisrange, automatisch generierte To-Do-Liste, vorgefertigter Verkaufstext und Nachverfolgung der Inserat-Laufzeit.

## Tech-Stack
- Flutter (iOS, Android, Web) — gleicher Stack wie bei Dice Days
- Supabase (Auth, Datenbank, Storage für Fotos)
- Eigenständiges neues Repo, keine Abhängigkeit zu Dice Days

## Datenquelle: BGG-Sync
- BGG XMLAPI2, Collection-Endpoint, um die eigene Sammlung zu importieren
- Übernommene Felder pro Spiel: Name, BGG-ID, Coverbild, `pricepaid` (falls in BGG gepflegt), Kaufdatum (falls vorhanden)
- Sync ist Pull/Polling (kein Realtime), manuell antriggerbar oder periodisch (z.B. täglich)
- Spiele ohne `pricepaid` in BGG: Feld bleibt leer, muss manuell nachgetragen werden können

## Kernfunktion 1: Swipe-Entscheidung
- Tinder-artiges Interface: ein Spiel nach dem anderen, drei mögliche Swipe-Ergebnisse:
  - **Behalten**
  - **Verkaufen** (Status wechselt zu "zum Verkauf vorgemerkt")
  - **Später entscheiden** (wandert zurück in den Stapel für eine spätere Session)
- Nach einer Swipe-Session: Übersicht, wie viele Spiele in welche Kategorie gewandert sind

## Kernfunktion 2: Marktwert-Einschätzung (kein automatischer Marktwert!)
Kein Rückgriff auf externe Preis-APIs (siehe Begründung unten) — stattdessen ein manuelles, aber strukturiertes System:

### Pro Spiel
- `kaufpreis` (aus BGG `pricepaid` oder manuell)
- `recherche_min`, `recherche_max` — vom Nutzer eingetragene Preisrange nach kurzem Scrollen durch Kleinanzeigen-Angebote (reine Zahlen, kein Notizfeld)
- `recherche_datum` — Zeitstempel der letzten Recherche
- `schmerzgrenze_prozent_override` — optional, überschreibt den globalen Wert für dieses Spiel

### Global (Einstellungen)
- `schmerzgrenze_prozent_default` (z.B. 65 %) — Standard-Anteil vom Kaufpreis, den der Nutzer mindestens erzielen möchte
- `recherche_intervall` (z.B. alle 90 Tage) — steuert, wann eine Recherche als veraltet gilt

### Berechnung & Darstellung
- `schmerzgrenze_wert = kaufpreis × (schmerzgrenze_prozent_override ?? schmerzgrenze_prozent_default)`
- Visualisierung pro Spiel als horizontaler Balken: `recherche_min` (links) bis `recherche_max` (rechts), mit Marker für `schmerzgrenze_wert` innerhalb (oder außerhalb, falls über dem Maximum)
- Nutzer wählt seinen `angebotspreis` frei innerhalb/nahe der Range — höher = maximaler Ertrag, niedriger = schneller Verkauf
- Ist `recherche_datum` älter als `recherche_intervall`: Spiel wird visuell als "Recherche veraltet" markiert

## Kernfunktion 3: To-Do-System pro Inserat
Für jedes Spiel im Status "zum Verkauf vorgemerkt" generiert die App automatisch eine To-Do-Liste, z.B.:
- [ ] Marktrecherche durchführen/aktualisieren (falls `recherche_datum` fehlt oder veraltet)
- [ ] Angebotspreis festlegen
- [ ] Foto von der Spieleschachtel machen
- [ ] Zustand beschreiben
- [ ] Verkaufstext generieren/prüfen
- [ ] Inserat auf Kleinanzeigen einstellen → Datum eintragen

To-Dos sind pro Spiel individuell abhakbar; erst wenn alle erledigt sind, gilt das Spiel als "bereit zum Inserieren".

Zusätzlich automatisch generiertes To-Do "Markt sondieren", sobald `recherche_datum` das `recherche_intervall` überschreitet — unabhängig vom Verkaufsstatus, damit auch behaltene, aber "beobachtete" Spiele aktuell bleiben.

## Kernfunktion 4: Verkaufstext-Baustein
- Vorlage mit Platzhaltern (Spielname, Zustand, Angebotspreis), ergänzt um fest hinterlegte Standard-Bausteine:
  - Zahlungsmethoden
  - Versandmodalitäten
  - Ausschluss der Gewährleistung (Privatverkauf)
- Bausteine in den Einstellungen editierbar, damit Denis den Text an seinen Stil anpassen kann
- Ein-Klick-Kopie des fertigen Texts (für Zwischenablage → Kleinanzeigen-App)

## Kernfunktion 5: Inserat-Tracking
- Beim Abhaken "Inserat eingestellt": Nutzer trägt das Datum ein (kein automatischer Abgleich mit Kleinanzeigen möglich, da keine öffentliche API für Privatnutzer existiert)
- App berechnet automatisch das Ablaufdatum: `inserat_datum + 60 Tage` (Standard-Laufzeit bei Kleinanzeigen)
- Erinnerung rechtzeitig vor Ablauf (z.B. 8 Tage vorher, analog zur Kleinanzeigen-eigenen Verlängerungslogik)
- Status pro Inserat: Online → Reserviert → Verkauft/Versendet (manuell gepflegt)

## Bewusst NICHT umgesetzt (mit Begründung)
- **Automatischer Marktwert über externe APIs**: Es existiert keine verlässliche, öffentliche API für aktuelle Brettspiel-Marktpreise. Scraping wäre instabil und ToS-widrig. Lösung: manuelle Recherche-Range statt Pseudo-Automatismus.
- **Automatisches Erstellen/Auslesen von Kleinanzeigen-Inseraten**: Keine öffentliche API für Privatnutzer verfügbar. Lösung: Nutzer trägt Inserat-Datum manuell ein, App übernimmt nur die Ablaufberechnung.

## Offene Punkte für spätere Iterationen
- Recherche-Intervall global vs. pro Spiel überschreibbar
- Umgang mit Spielen ohne BGG `pricepaid`
- Batch-Aktionen (mehrere Spiele gleichzeitig als "zum Verkauf" markieren)
