-- steuerung.lua
-- Laeuft auf dem (versteckten) Command Computer einer Station.
-- Die Steuerung erledigt die eigentliche Arbeit:
--   * nimmt Tastendruecke vom Telefon (ueber Kabel) entgegen,
--   * telefoniert ueber das Ender-Modem mit den anderen Stationen,
--   * setzt das End-Transitportal per /setblock.
-- Hinweis: Bildschirmtexte ohne Umlaute, weil ComputerCraft sie nicht richtig anzeigt.

-- ===== Feste Werte =====
local PROTOKOLL = "mc-teleporter"     -- "Funkkanal-Name", damit sich nur Teleporter verstehen
local KANAL = 4711                    -- Leitungsnummer zum Telefon auf dem Kabel
local CONFIG_DATEI = "teleporter.cfg" -- Einstellungen aus dem Installationsprogramm
local PORTAL_DAUER = 10               -- so viele Sekunden bleibt das Portal offen
local KLINGEL_DAUER = 30              -- so viele Sekunden klingelt es hoechstens

-- ===== Einstellungen laden =====
local function ladeEinstellungen()
  if not fs.exists(CONFIG_DATEI) then return nil end
  local datei = fs.open(CONFIG_DATEI, "r")
  local inhalt = datei.readAll()
  datei.close()
  return textutils.unserialize(inhalt)
end

local cfg = ladeEinstellungen()
if not cfg then
  print("Keine Einstellungen gefunden.")
  print("Bitte zuerst das Installationsprogramm ausfuehren.")
  return
end

-- Nur ein Command Computer hat die "commands"-Funktionen (fuer /setblock).
if not commands then
  print("Fehler: Das ist kein Command Computer.")
  return
end

-- Beide Modems suchen: Ender-Modem (kabellos) und Kabel-Modem.
local funk = peripheral.find("modem", function(_, m) return m.isWireless() end)
local kabel = peripheral.find("modem", function(_, m) return not m.isWireless() end)
if not funk then
  print("Fehler: Kein Ender-Modem gefunden.")
  return
end
if not kabel then
  print("Fehler: Kein kabelgebundenes Modem gefunden.")
  return
end
local kabelName = peripheral.getName(kabel)

-- Funknetz (rednet) nur auf dem Ender-Modem einschalten.
rednet.open(peripheral.getName(funk))
-- Leitung zum Telefon auf dem Kabel oeffnen.
kabel.open(KANAL)

-- Die eigene Nummer im Funknetz anmelden, damit andere Stationen uns finden.
-- Das ist wie ein Eintrag im Telefonbuch: Nummer -> diese Steuerung.
local ok = pcall(rednet.host, PROTOKOLL, cfg.nummer)
if not ok then
  print("Fehler: Die Nummer " .. cfg.nummer .. " wird schon")
  print("von einer anderen Station benutzt.")
  return
end

-- ===== Bildschirm (wird auf dem Telefon UND hier angezeigt) =====
local eingabe = ""      -- die Ziffern, die gerade getippt werden
local letztesBild = {}  -- zuletzt angezeigter Inhalt, falls das Telefon neu startet

local function sendeBild()
  kabel.transmit(KANAL, KANAL, { typ = "bild", zeilen = letztesBild })
end

local function bildschirm(zeilen)
  letztesBild = { "=== Teleporter " .. cfg.nummer .. " ===", "" }
  for _, zeile in ipairs(zeilen) do
    table.insert(letztesBild, zeile)
  end
  -- Hier auf der Steuerung anzeigen ...
  term.clear()
  term.setCursorPos(1, 1)
  for _, zeile in ipairs(letztesBild) do
    print(zeile)
  end
  -- ... und ans Telefon schicken.
  sendeBild()
end

-- Der normale Bildschirm: wartet auf eine Nummer.
local function zeigeBereit(hinweis)
  bildschirm({
    "Nummer waehlen (5 Ziffern),",
    "dann Enter druecken.",
    "",
    "> " .. eingabe,
    "",
    hinweis or "",
  })
end

-- ===== Auf das naechste Ereignis warten =====
-- Tastendruecke vom Telefon werden so umgewandelt, als waeren sie hier
-- an der Steuerung getippt worden. Angenommen wird nur, was ueber das
-- KABEL kommt, nicht ueber Funk.
local function naechstesEreignis()
  while true do
    local ereignis, a, b, c, d = os.pullEvent()
    if ereignis == "modem_message" then
      -- a = Modem, b = Kanal, d = Nachricht
      if a == kabelName and b == KANAL and type(d) == "table" then
        if d.typ == "char" and type(d.wert) == "string" then
          return "char", d.wert
        elseif d.typ == "key" and type(d.wert) == "number" then
          return "key", d.wert
        elseif d.typ == "hallo" then
          sendeBild() -- Telefon wurde (neu) gestartet
        end
      end
      -- alle anderen Modem-Nachrichten ignorieren
    else
      return ereignis, a, b, c
    end
  end
end

-- Wenn waehrend eines Gespraechs ein weiterer Anruf kommt, antworten wir "besetzt".
local function besetztFallsAnruf(ereignis, absender, nachricht, protokoll)
  if ereignis == "rednet_message" and protokoll == PROTOKOLL
      and type(nachricht) == "table" and nachricht.typ == "anruf" then
    rednet.send(absender, { typ = "besetzt" }, PROTOKOLL)
  end
end

-- ===== Portal =====
-- Setzt das End-Transitportal, wartet und entfernt es wieder.
local function portalOeffnen(ziel)
  if type(ziel) ~= "table" or not tonumber(ziel.x) or not tonumber(ziel.y) or not tonumber(ziel.z) then
    zeigeBereit("Fehler: Ungueltige Zielkoordinaten.")
    return
  end
  local p = cfg.portal
  local befehl = string.format(
    "setblock %d %d %d minecraft:end_gateway{ExitPortal:{X:%d,Y:%d,Z:%d},ExactTeleport:1b}",
    p.x, p.y, p.z, math.floor(ziel.x), math.floor(ziel.y), math.floor(ziel.z))
  if not commands.exec(befehl) then
    zeigeBereit("Fehler: Portal konnte nicht gesetzt werden.")
    return
  end

  -- Countdown anzeigen, solange das Portal offen ist.
  for rest = PORTAL_DAUER, 1, -1 do
    bildschirm({ "Portal ist offen! Bitte eintreten.", "", "Schliesst in " .. rest .. " Sekunden." })
    sleep(1)
  end

  -- Portal wieder durch Luft ersetzen.
  commands.exec(string.format("setblock %d %d %d minecraft:air", p.x, p.y, p.z))
  zeigeBereit("Portal geschlossen.")
end

-- ===== Selbst anrufen =====
local function anrufen(nummer)
  if nummer == cfg.nummer then
    zeigeBereit("Das ist die eigene Nummer.")
    return
  end

  bildschirm({ "Suche " .. nummer .. " ..." })
  -- Im "Telefonbuch" des Funknetzes nachsehen, welche Steuerung diese Nummer hat.
  local zielId = rednet.lookup(PROTOKOLL, nummer)
  if not zielId then
    zeigeBereit("Teilnehmer " .. nummer .. " nicht erreichbar.")
    return
  end

  rednet.send(zielId, { typ = "anruf", von = cfg.nummer }, PROTOKOLL)
  bildschirm({ "Es klingelt bei " .. nummer .. " ..." })

  -- Auf Antwort warten (etwas laenger als die Klingeldauer beim Empfaenger).
  local frist = os.startTimer(KLINGEL_DAUER + 5)
  while true do
    local ereignis, a, b, c = naechstesEreignis()
    if ereignis == "rednet_message" and a == zielId and c == PROTOKOLL and type(b) == "table" then
      if b.typ == "angenommen" then
        portalOeffnen(b.ziel)
        return
      elseif b.typ == "abgelehnt" then
        zeigeBereit(nummer .. " hat abgelehnt.")
        return
      elseif b.typ == "besetzt" then
        zeigeBereit(nummer .. " ist besetzt.")
        return
      end
    elseif ereignis == "timer" and a == frist then
      zeigeBereit("Niemand hat abgenommen.")
      return
    else
      besetztFallsAnruf(ereignis, a, b, c)
    end
  end
end

-- ===== Angerufen werden =====
local function anrufBeantworten(absenderId, vonNummer)
  local annehmen = cfg.automatisch

  if not annehmen then
    bildschirm({ "Anruf von " .. vonNummer .. "!", "", "Annehmen?  J = ja,  N = nein" })
    local frist = os.startTimer(KLINGEL_DAUER)
    while true do
      local ereignis, a, b, c = naechstesEreignis()
      if ereignis == "char" and (a == "j" or a == "J") then
        annehmen = true
        break
      elseif ereignis == "char" and (a == "n" or a == "N") then
        break
      elseif ereignis == "timer" and a == frist then
        break
      else
        besetztFallsAnruf(ereignis, a, b, c)
      end
    end
  end

  if annehmen then
    -- Unsere Ankunftskoordinaten an den Anrufer schicken.
    rednet.send(absenderId, { typ = "angenommen", ziel = cfg.ankunft }, PROTOKOLL)
    zeigeBereit("Anruf von " .. vonNummer .. " angenommen.")
  else
    rednet.send(absenderId, { typ = "abgelehnt" }, PROTOKOLL)
    zeigeBereit("Anruf von " .. vonNummer .. " abgelehnt.")
  end
end

-- ===== Hauptschleife =====
-- Wartet immer wieder auf das naechste Ereignis: Tastendruck oder Funknachricht.
zeigeBereit()
while true do
  local ereignis, a, b, c = naechstesEreignis()

  if ereignis == "char" and a:match("^%d$") and #eingabe < 5 then
    -- Eine Ziffer wurde getippt.
    eingabe = eingabe .. a
    zeigeBereit()

  elseif ereignis == "key" and a == keys.backspace then
    -- Letzte Ziffer loeschen.
    eingabe = eingabe:sub(1, -2)
    zeigeBereit()

  elseif ereignis == "key" and (a == keys.enter or a == keys.numPadEnter) then
    if #eingabe == 5 then
      local nummer = eingabe
      eingabe = ""
      anrufen(nummer)
    else
      zeigeBereit("Bitte genau 5 Ziffern eingeben.")
    end

  elseif ereignis == "rednet_message" and c == PROTOKOLL
      and type(b) == "table" and b.typ == "anruf" then
    -- Jemand ruft an.
    anrufBeantworten(a, tostring(b.von))
  end
end
