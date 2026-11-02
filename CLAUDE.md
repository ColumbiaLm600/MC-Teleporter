# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

Ein Teleporter für Minecraft, programmiert in **Lua** mit der Mod **ComputerCraft** (aktuell gepflegt als **CC: Tweaked**). Das Projekt steht noch ganz am Anfang. Es gibt noch keinen Code, kein Build-System und keine Tests.

- **Minecraft 1.20.1** mit **Forge**, läuft auf einem **Server** (Mehrspieler)
- Ziel ist zuerst ein **MVP** (kleinste funktionierende Version). Keine Zusatzfunktionen, bevor das MVP läuft.
- **Erst besprechen, dann programmieren:** Funktionsumfang und Aufbau werden gemeinsam mit dem Nutzer abgestimmt, bevor Code geschrieben wird.
- Noch offen: genaue CC: Tweaked-Version auf dem Server.

## Nutzer

- Antworte immer auf **Deutsch**.
- Der Nutzer ist **kein Entwickler**. Erkläre Programmierthemen einfach, ohne Fachjargon. Nötige Fachbegriffe kurz in einfachen Worten erklären.
- Der Nutzer kennt sich mit **Minecraft** aus und hat bereits versucht, den Teleporter mit **Commandblöcken** zu bauen. Vergleiche mit Commandblöcken und Minecraft-Befehlen (z. B. `/tp`) eignen sich gut zum Erklären.
- Code-Kommentare auf Deutsch schreiben, damit der Nutzer den Code nachvollziehen kann.

## Recherche

- Recherche im Internet ist erlaubt. **Zuerst offizielle Quellen** nutzen, erst danach Foren, Blogs o. Ä.:
  - CC: Tweaked-Dokumentation: https://tweaked.cc
  - Lua-Handbuch: https://www.lua.org/manual/
  - Minecraft Wiki: https://minecraft.wiki
- Gesammelte Quellen stehen in `Quellen.md`. Diese Datei zuerst lesen und neue, genutzte Quellen dort ergänzen.

## Technische Hinweise

- ComputerCraft nutzt **Lua 5.2** mit einigen Funktionen aus Lua 5.3. Nicht jede Funktion aus dem allgemeinen Lua-Handbuch ist verfügbar. Im Zweifel bei tweaked.cc nachsehen.
- Spieler teleportieren (`/tp`) geht nur mit einem **Command Computer**. Dieser kann über die `commands`-API Minecraft-Befehle ausführen, lässt sich aber nur im Kreativmodus bzw. als Operator platzieren und bedienen. Normale Computer können niemanden teleportieren.
- Programme laufen im Spiel auf dem Computer. Testen geschieht deshalb im Spiel (Datei auf den Computer bringen, z. B. per `edit`, `pastebin` oder `wget`, und dann starten). Bevor ein Testweg vorgeschlagen wird, beim Nutzer nachfragen, wie er Dateien auf den Computer bringt.
