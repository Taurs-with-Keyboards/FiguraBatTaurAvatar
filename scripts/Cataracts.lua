-- Irri's idea for the script name :)

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local s, c = pcall(require, "scripts.ColorProperties")
if not s then c = {} end

-- Config setup
config:name("BatTaur")
local blind = config:load("BlindState") or 1

-- Variable
local timer = 0

-- Check if a bat makes a sound near the player
function events.ON_PLAY_SOUND(id, pos, vol, pitch, loop, cat, path)
	
	-- Don't do anything if not using the echolocation setting or the user isn't loaded
	if blind ~= 3 or not player:isLoaded() then return end
	
	-- Make sure the sound is (most likely) played by the user
	if (player:getPos() - pos):length() > 0.05 then return end
	
	-- If sound contains "bat", but not "takeoff", set timer to 5 seconds
	if id:find("bat") and not id:find("takeoff") then
		timer = 100
	end
	
end

function events.TICK()
	
	-- Decrease timer
	timer = math.max(timer - 1, 0)
	
end

function events.RENDER(delta, context)
	
	-- Set post effect
	renderer:postEffect(blind > 1 and timer == 0 and "blobs2" or nil)
	
end

-- Blindness states
local function setBlind(i)
	
	blind = ((blind + i - 1) % 3) + 1
	config:save("BlindState", blind)
	
end

-- Table setup
local t = {}

-- Action
t.blindAct = action_wheel:newAction()
	:onLeftClick(function() setBlind(1) end)
	:onRightClick(function() setBlind(-1) end)
	:onScroll(setBlind)

-- Blind context info table
local blindInfo = {
	{
		title = {label = {text = "Not Blind", color = "green"}, text = "20/20 Vision"},
		item  = "ender_eye",
		color = "000000"
	},
	{
		title = {label = {text = "Blind", color = "red"}, text = "See an eye doctor."},
		item  = "ender_pearl"
	},
	{
		title = {label = {text = "Echolocation", color = "yellow"}, text = "Blind, unless you scream!\n(Check your keybinds/origin for screaming options!)"},
		item  = "amethyst_shard"
	}
}

-- Update action
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		local actionSetup = blindInfo[blind]
		t.blindAct
			:title(toJson(
				{
					"",
					{text = "Blindness\n\n", bold = true, color = c.primary},
					{text = "While bats aren\'t actually blind, who says you can\'t be?\n\n", color = c.secondary},
					{text = "Current configuration: ", bold = true, color = c.secondary},
					{text = actionSetup.title.label.text, color = actionSetup.title.label.color},
					{text = " | "},
					{text = actionSetup.title.text, color = c.secondary}
				}
			))
			:color(actionSetup.color or c.active)
			:item(itemCheck(actionSetup.item))
		
		for _, act in pairs(t) do
			act:hoverColor(c.hover)
		end
		
	end
	
end

-- Return action
return t