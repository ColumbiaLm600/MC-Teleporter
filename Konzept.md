# Konzept: MC-Teleporter (MVP)

Stand: 2026-11-02, gemeinsam abgestimmt.

## Idee

Teleporter wie ein Telefon: An einer Station wird eine 5-stellige Nummer gewählt, die Zielstation „klingelt“, und nach dem Annehmen entsteht beim Anrufer ein End-Transitportal (End Gateway), das genau zur Ankunftsstelle der Zielstation führt.

## Aufbau einer Station

- **Command Computer**: führt Minecraft-Befehle aus (z. B. `setblock`) und kennt seine eigenen Koordinaten (`commands.getBlockPosition()`).
- **Ender-Modem**: Funkverbindung zwischen allen Stationen über `rednet`, ohne Reichweitenbegrenzung.

## Ablauf eines Anrufs

1. Spieler tippt am Anrufer-Computer eine 5-stellige Nummer per Tastatur ein.
2. Anrufer sucht im Funknetz die Station mit dieser Nummer.
3. Gefunden: Empfänger „klingelt“ (Anzeige mit Nummer des Anrufers). Nicht gefunden: „Teilnehmer nicht erreichbar“.
4. Empfänger nimmt an:
   - **manuell**: ein Spieler drückt am Empfänger eine Taste (J/N), oder
   - **automatisch**: die Station ist so eingestellt, dass sie selbst abhebt.
5. Empfänger schickt seine Ankunftskoordinaten an den Anrufer.
6. Anrufer setzt an seiner Portalstelle ein End Gateway mit diesen Zielkoordinaten.
7. Nach ca. 10 Sekunden wird das Portal wieder entfernt.

Das Portal führt **nur in eine Richtung**. Für den Rückweg ruft man von der anderen Station zurück.

## Installationsprogramm

Ein Befehl im Spiel lädt das Programm von GitHub herunter (Repository ist dafür öffentlich). Danach fragt es:

- Nummer der Station (5-stellig, Prüfung ob schon vergeben)
- Position des Portals relativ zum Computer
- Ankunftsposition relativ zum Computer
- Annehmen manuell oder automatisch

Die Einstellungen werden auf dem Computer gespeichert, und die Station startet automatisch, auch nach einem Server-Neustart.

## Umfang des MVP

- Mindestens 2 Stationen in derselben Dimension (Oberwelt)
- Wählen und Annehmen per Tastatur
- Manuelles und automatisches Annehmen
- Portal für ca. 10 Sekunden
- Installationsprogramm

## Später (nicht im MVP)

- Telefonbuch / Namen für Nummern
- Monitor mit Tasten zum Antippen
- Klingelton über Lautsprecher
- Teleport in andere Dimensionen

## Vor dem Programmieren zu prüfen

- Server: `enable-command-block=true` in `server.properties` (vermutlich nötig für Command Computer)
- CC: Tweaked-Konfiguration: HTTP-Zugriff erlaubt, damit der Download von GitHub klappt
- Genaue CC: Tweaked-Version auf dem Server
- Datenformat des End Gateways in 1.20.1: vermutlich `ExitPortal:{X:..,Y:..,Z:..}` und `ExactTeleport:1b`. Das Minecraft Wiki zeigt bereits das neuere Format `exit_portal` als Zahlenliste, deshalb im Spiel testen.
- Ob End Gateways in 1.20.1 in andere Dimensionen führen (vermutlich nicht)
