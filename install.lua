-- install.lua
-- Installationsprogramm fuer den Teleporter. Dasselbe Programm fuer beide Computer:
--   * auf dem Command Computer wird die STEUERUNG eingerichtet (mit Fragen),
--   * auf einem normalen Computer wird das TELEFON eingerichtet (ohne Fragen).
-- Start im Spiel mit:
--   wget run https://raw.githubusercontent.com/ColumbiaLm600/MC-Teleporter/main/install.lua
-- Hinweis: Bildschirmtexte ohne Umlaute, weil ComputerCraft sie nicht richtig anzeigt.

local ADRESSE = "https://raw.githubusercontent.com/ColumbiaLm600/MC-Teleporter/main/"
local PROTOKOLL = "mc-teleporter"
local CONFIG_DATEI = "teleporter.cfg"

-- Ist das ein Command Computer? Dann Steuerung, sonst Telefon.
local istSteuerung = (commands ~= nil)
local programm = istSteuerung and "steuerung.lua" or "telefon.lua"

term.clear()
term.setCursorPos(1, 1)
if istSteuerung then
  print("=== Teleporter: STEUERUNG einrichten ===")
else
  print("=== Teleporter: TELEFON einrichten ===")
end
print()

-- ===== Modems pruefen =====
local funk = peripheral.find("modem", function(_, m) return m.isWireless() end)
local kabel = peripheral.find("modem", function(_, m) return not m.isWireless() end)
if not kabel then
  print("Fehler: Kein kabelgebundenes Modem gefunden.")
  print("Bitte ein Modem anbauen und Telefon und")
  print("Steuerung mit Netzwerkkabel verbinden.")
  return
end
if istSteuerung and not funk then
  print("Fehler: Kein Ender-Modem gefunden.")
  print("Die Steuerung braucht zusaetzlich ein Ender-Modem.")
  return
end

-- ===== Programm herunterladen =====
write("Lade " .. programm .. " ... ")
local antwort = http.get(ADRESSE .. programm)
if not antwort then
  print("fehlgeschlagen!")
  return
end
local inhalt = antwort.readAll()
antwort.close()
local datei = fs.open(programm, "w")
datei.write(inhalt)
datei.close()
print("ok")

-- Startdatei schreiben, damit das Programm nach jedem Neustart von selbst laeuft
-- (wie ein Commandblock auf "Immer aktiv").
datei = fs.open("startup.lua", "w")
datei.write('shell.run("' .. programm .. '")\n')
datei.close()
print()

-- ===== Telefon: fertig, keine Fragen =====
if not istSteuerung then
  print("Fertig! Der Computer startet neu ...")
  sleep(3)
  os.reboot()
  return
end

-- ===== Ab hier nur fuer die Steuerung =====

-- Stellt eine Frage und gibt die getippte Antwort zurueck.
local function frage(text)
  print(text)
  write("> ")
  return read()
end

-- Fragt nach drei Koordinaten, z. B. "50 65 -120".
-- Erlaubt auch die F3-Schreibweise "50 / 65 / -120" und Kommazahlen
-- (die werden auf den Block abgerundet).
local function frageKoordinaten(text)
  while true do
    local antwort = frage(text)
    local x, y, z = antwort:match("^%s*(%-?[%d%.]+)[%s,/]+(%-?[%d%.]+)[%s,/]+(%-?[%d%.]+)%s*$")
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if x and y and z then
      return { x = math.floor(x), y = math.floor(y), z = math.floor(z) }
    end
    print("Bitte drei Zahlen eingeben, z.B. 50 65 -120")
  end
end

-- Fragt eine Ja/Nein-Frage, Antwort j oder n.
local function frageJaNein(text)
  while true do
    local antwort = frage(text .. " (j/n)"):lower()
    if antwort == "j" then return true end
    if antwort == "n" then return false end
  end
end

-- Prueft, ob an einer Stelle Luft ist. Wenn nicht, wird nachgefragt.
local function stelleOk(pos)
  local ok, info = pcall(commands.getBlockInfo, pos.x, pos.y, pos.z)
  if ok and info and info.name ~= "minecraft:air" then
    print("Achtung: Dort steht " .. info.name .. ".")
    return frageJaNein("Trotzdem verwenden?")
  end
  return true
end

-- 1. Nummer
rednet.open(peripheral.getName(funk))
local nummer
while true do
  nummer = frage("Nummer dieser Station (5 Ziffern):")
  if not nummer:match("^%d%d%d%d%d$") then
    print("Bitte genau 5 Ziffern eingeben.")
  else
    print("Pruefe, ob die Nummer frei ist ...")
    local id = rednet.lookup(PROTOKOLL, nummer)
    if id and id ~= os.getComputerID() then
      print("Diese Nummer ist schon vergeben.")
    else
      break
    end
  end
end
print()

-- 2. und 3. Positionen
local cx, cy, cz = commands.getBlockPosition()
print("Zur Orientierung: Diese Steuerung")
print("steht bei " .. cx .. " " .. cy .. " " .. cz)
print()

local portal
repeat
  portal = frageKoordinaten("Wo soll das Portal entstehen? (X Y Z)")
until stelleOk(portal)

local ankunft
repeat
  ankunft = frageKoordinaten("Wo sollen Besucher ankommen? (X Y Z)")
until stelleOk(ankunft)
print()

-- 4. Annahme-Art
local automatisch = frageJaNein("Anrufe automatisch annehmen?")

-- Einstellungen speichern
datei = fs.open(CONFIG_DATEI, "w")
datei.write(textutils.serialize({
  nummer = nummer,
  portal = portal,
  ankunft = ankunft,
  automatisch = automatisch,
}))
datei.close()

print()
print("Fertig! Der Computer startet neu ...")
sleep(3)
os.reboot()
