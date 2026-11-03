# Konzept: MC-Teleporter (MVP)

Stand: 2026-11-03, gemeinsam abgestimmt.

## Idee

Teleporter wie ein Telefon: An einer Station wird eine 5-stellige Nummer gewählt, die Zielstation „klingelt“, und nach dem Annehmen entsteht beim Anrufer ein End-Transitportal (End Gateway), das genau zur Ankunftsstelle der Zielstation führt.

## Aufbau einer Station

Jede Station besteht aus **zwei Computern**, die mit einem **Netzwerkkabel** verbunden sind (Absprache 2026-11-03):

- **Telefon** (normaler Computer + kabelgebundenes Modem): steht sichtbar, **jeder Spieler** kann es bedienen. Es zeigt nur den Bildschirm an und gibt Tastendrücke an die Steuerung weiter. Selbst kann es keine Befehle ausführen.
- **Steuerung** (Command Computer + kabelgebundenes Modem + Ender-Modem): steht versteckt bzw. geschützt und wird nur vom Admin eingerichtet. Sie kennt die Koordinaten, telefoniert über das Ender-Modem (`rednet`) mit den anderen Stationen und setzt das Portal per `setblock`. Ihre eigene Position kennt sie über `commands.getBlockPosition()`.

**Grund:** Command Computer können nur Operatoren bedienen. So kann trotzdem jeder telefonieren, aber niemand kann über das Telefon eigene Befehle ausführen. Ein Commandblock als Peripheriegerät wurde verworfen, weil man darüber beliebige Befehle ausführen könnte.

Die Verbindung Telefon ↔ Steuerung läuft nur über das Kabel. Die Steuerung nimmt Tastendrücke nur vom Kabel-Modem an, nicht über Funk.

## Ablauf eines Anrufs

1. Ein Spieler tippt am Telefon eine 5-stellige Nummer per Tastatur ein.
2. Die Steuerung des Anrufers sucht im Funknetz die Station mit dieser Nummer.
3. Gefunden: Der Empfänger „klingelt“ (Anzeige mit der Nummer des Anrufers). Nicht gefunden: „Teilnehmer nicht erreichbar“.
4. Der Empfänger nimmt an:
   - **manuell**: Ein Spieler drückt am Telefon des Empfängers eine Taste (J/N), oder
   - **automatisch**: Die Station ist so eingestellt, dass sie selbst abhebt.
5. Der Empfänger schickt seine Ankunftskoordinaten an den Anrufer.
6. Der Anrufer setzt an seiner Portalstelle ein End Gateway mit diesen Zielkoordinaten.
7. Nach ca. 10 Sekunden wird das Portal wieder entfernt.

Das Portal führt **nur in eine Richtung**. Für den Rückweg ruft man von der anderen Station zurück.

## Installationsprogramm

Ein Befehl im Spiel lädt das Installationsprogramm von GitHub herunter (das Repository ist dafür öffentlich). Es ist **dasselbe Programm für beide Computer** und erkennt selbst, ob es auf dem Telefon oder auf der Steuerung läuft.

- **Telefon:** Es gibt keine Fragen. Das Programm wird nur heruntergeladen und eingerichtet.
- **Steuerung:** Es fragt
  - die Nummer der Station (5-stellig, mit Prüfung, ob sie schon vergeben ist),
  - die Position des Portals als **feste Koordinaten** (X Y Z, wie in F3 angezeigt),
  - die Ankunftsposition als feste Koordinaten,
  - ob Anrufe manuell oder automatisch angenommen werden.

Die Einstellungen werden auf der Steuerung gespeichert. Beide Computer starten das Programm automatisch, auch nach einem Server-Neustart.

## Umfang des MVP

- Mindestens 2 Stationen (je Telefon + Steuerung) in derselben Dimension (Oberwelt)
- Wählen und Annehmen per Tastatur am Telefon
- Manuelles und automatisches Annehmen
- Portal für ca. 10 Sekunden
- Installationsprogramm

## Später (nicht im MVP)

- Telefonbuch / Namen für Nummern
- Monitor mit Tasten zum Antippen
- Klingelton über Lautsprecher
- Teleport in andere Dimensionen
- Absicherung gegen gefälschte Funknachrichten (z. B. ein gemeinsames Passwort aller Stationen). Bekannte Lücke im MVP: Jemand mit eigenem Computer und Ender-Modem könnte sich als Station ausgeben und sich falsche Zielkoordinaten schicken lassen.

## Vor dem Programmieren zu prüfen

- ~~Server: `enable-command-block=true`~~ → erledigt, ist aktiv (2026-11-03)
- ~~HTTP-Zugriff für Download von GitHub~~ → erledigt, `wget` klappt (2026-11-03)
- ~~CC: Tweaked-Version~~ → 1.113.1 (CraftOS 1.9), Minecraft 1.20.1 Forge
- ~~Datenformat des End Gateways~~ → im Spiel getestet (2026-11-03): `/setblock X Y Z minecraft:end_gateway{ExitPortal:{X:..,Y:..,Z:..},ExactTeleport:1b}` funktioniert, Spieler landet genau am Ziel.
- Ob End Gateways in 1.20.1 in andere Dimensionen führen (vermutlich nicht)
