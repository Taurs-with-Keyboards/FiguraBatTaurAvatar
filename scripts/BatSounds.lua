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
local sync    = require("lib.LetThatSyncFig")

-- Variables
local power = false
local cooldown = 0

-- Keybinds
local screechKeybind = keybinds:newKeybind("Bat Screech", "key.keyboard.keypad.2")
	:onPress(function() if power then host:setActionbar("Hey! Your origin has a button for this! Use that instead!") return end pings.playBatScreech() cooldown = 30 end)

-- Sync config keybinds
sync.keybind(screechKeybind, "ScreechKeybind")

function events.TICK()
	
	-- Check for power
	power = origins.hasPower(player, "battaur:echolocation")
	
	-- Reduce cooldown
	cooldown = math.max(cooldown - 1, 0)
	
	-- Disable keybind if cooldown is active, and player isnt dead
	screechKeybind:enabled(cooldown == 0 and player:getDeathTime() == 0)
	
end