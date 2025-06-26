-- Play sound
function pings.playBatScreech()
	
	if player:isLoaded() then
		sounds:playSound("entity.bat.ambient", player:getPos(), 0.6, math.random()*0.35+0.85)
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local origins = require("lib.OriginsAPI")

-- Config setup
config:name("BatTaur")

-- Variables
local power = false
local cooldown = 0

-- Screech Keybind
local screechBind   = config:load("ScreechKeybind") or "key.keyboard.keypad.2"
local setScreechKey = keybinds:newKeybind("Bat Screech"):onPress(function() if power then host:setActionbar("Hey! Your origin has a button for this! Use that instead!") return end pings.playBatScreech() cooldown = 30 end):key(screechBind)

function events.TICK()
	
	-- Check for power
	power = origins.hasPower(player, "battaur:echolocation")
	
	-- Reduce cooldown
	cooldown = math.max(cooldown - 1, 0)
	
	-- Disable keybind if cooldown is active, and player isnt dead
	setScreechKey:enabled(cooldown == 0 and player:getDeathTime() == 0)
	
end

-- Keybind updater
function events.TICK()
	
	local screechKey = setScreechKey:getKey()
	if screechKey ~= screechBind then
		screechBind = screechKey
		config:save("ScreechKeybind", screechKey)
	end
	
end