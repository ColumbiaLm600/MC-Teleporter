-- telefon.lua
-- Laeuft auf dem normalen Computer, den jeder Spieler bedienen darf.
-- Das Telefon ist nur "Bildschirm und Tastatur": Es schickt jeden Tastendruck
-- uebers Kabel an die Steuerung und zeigt an, was die Steuerung zurueckschickt.
-- Es fuehrt selbst keine Minecraft-Befehle aus.
-- Hinweis: Bildschirmtexte ohne Umlaute, weil ComputerCraft sie nicht richtig anzeigt.

local KANAL = 4711 -- "Leitungsnummer" zwischen Telefon und Steuerung auf dem Kabel

-- Kabelgebundenes Modem suchen (also eines, das NICHT kabellos ist).
local kabel = peripheral.find("modem", function(_, m) return not m.isWireless() end)
if not kabel then
  print("Fehler: Kein kabelgebundenes Modem gefunden.")
  print("Bitte ein Modem anbauen und per Kabel")
  print("mit der Steuerung verbinden.")
  return
end
kabel.open(KANAL)

-- Zeigt die Zeilen an, die von der Steuerung kommen.
local function zeige(zeilen)
  term.clear()
  term.setCursorPos(1, 1)
  for _, zeile in ipairs(zeilen) do
    print(zeile)
  end
end

-- Schickt eine Nachricht uebers Kabel an die Steuerung.
local function sende(nachricht)
  kabel.transmit(KANAL, KANAL, nachricht)
end

zeige({ "Verbinde mit der Steuerung ...", "", "Falls das so bleibt: Kabel und", "Modems pruefen." })
-- Die Steuerung bitten, den aktuellen Bildschirm zu schicken.
sende({ typ = "hallo" })

while true do
  local ereignis, a, b, c, d = os.pullEvent()

  if ereignis == "char" then
    -- Ein Zeichen wurde getippt (Ziffer, J, N ...).
    sende({ typ = "char", wert = a })

  elseif ereignis == "key" and (a == keys.backspace or a == keys.enter or a == keys.numPadEnter) then
    -- Nur die Sondertasten weitergeben, die das Programm braucht.
    sende({ typ = "key", wert = a })

  elseif ereignis == "modem_message" and b == KANAL and type(d) == "table" and d.typ == "bild" then
    -- Neuer Bildschirminhalt von der Steuerung.
    zeige(d.zeilen)
  end
end
