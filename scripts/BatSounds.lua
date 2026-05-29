-- Play sound
function pings.playBatScreech()
	
	if player:isLoaded() then
		sounds:playSound("entity.bat.ambient", player:getPos(), 0.6, math.random()*0.35+0.85)
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local origins  = require("lib.OriginsAPI")
local keybound = require("lib.Keybound")

-- Variable
local cooldown = 0

-- Cooldown event
local function createCooldown()
	
	-- Set cooldown
	cooldown = 30
	
	-- Create event
	events.TICK:register(function()
		
		-- Decrease cooldown
		cooldown = math.max(cooldown - 1, 0)
		
		-- Remove tick event
		if cooldown == 0 then
			events.TICK:remove("ScreechCooldown")
		end
		
	end, "ScreechCooldown")
	
end

-- Setup keybind
local screechKeybind = keybound.new(
	keybinds
		:newKeybind("Bat Screech", "key.keyboard.keypad.2")
		:onPress(function()
			
			-- If player is dead, return early
			if player:getDeathTime() ~= 0 then return end
			
			-- If power exist, return early
			if origins.getPowerData(player)["battaur:echolocation"] then
				return host:setActionbar("Hey! Your origin has a button for this! Use that instead!")
			end
			
			-- If no cooldown, preform functions
			if cooldown == 0 then
				pings.playBatScreech()
				createCooldown()
			end
			
		end),
	"ScreechKeybind"
)