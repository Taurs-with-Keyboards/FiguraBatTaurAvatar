-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local origins = require("lib.OriginsAPI")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.BatTaur

-- Variable
local rest = false

-- Table setup
v = {}

-- Animation variables
v.snap = 0

function events.TICK()
	
	-- Variables
	local pos = player:getPos()
	local vel = player:getVelocity()
	local block, hitPos = raycast:block(pos, pos + vec(0, 10, 0))
	
	-- Origins powers
	local hasRestPower = origins.hasPower(player, "battaur:ceiling_snoozer_toggle")
	local restData = origins.getPowerData(player, "battaur:ceiling_snoozer_toggle") or 0
	
	-- Stop Rest animation
	if vel:length() ~= 0 or block:isAir() then
		rest = false
	end
	
	-- Start rest animation
	if restData == 1 then
		rest = true
	end
	
	-- Animation
	anims.resting:playing(rest)
	
end

function events.RENDER(delta, context)
	
	-- Resting variables
	if rest then
		
		-- Variables
		local pos = player:getPos(delta)
		local block, hitPos = raycast:block(pos, pos + vec(0, 10, 0))
		
		-- Pehkui scaling
		local nbt   = player:getNbt()
		local types = nbt["pehkui:scale_data_types"]
		local playerScale = (
			types and
			types["pehkui:base"] and
			types["pehkui:base"]["scale"] or 1)
		local height = (
			types and
			types["pehkui:height"] and
			types["pehkui:height"]["scale"] or 1)
		local modelHeight = (
			types and
			types["pehkui:model_height"] and
			types["pehkui:model_height"]["scale"] or 1)
		local heightOffset = height * modelHeight * playerScale
		
		-- Store animation variables
		v.snap = (hitPos.y - pos.y) * (16 / heightOffset)
		
	end
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.resting, ticks = {20,20} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	blend.anim:blendTime(table.unpack(blend.ticks)):blendCurve("easeOutQuad")
end

-- Fixing spyglass jank
function events.RENDER(delta, context)
	
	local rot = vanilla_model.HEAD:getOriginRot()
	rot.x = math.clamp(rot.x, -90, 30)
	parts.group.Spyglass:offsetRot(rot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end

-- Play rest anim
function pings.animPlayRest()
	
	rest = true
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local s, c = pcall(require, "scripts.ColorProperties")
if not s then c = {} end

-- Rest keybind
local restBind   = config:load("AnimRestKeybind") or "key.keyboard.keypad.1"
local setRestKey = keybinds:newKeybind("Rest Animation"):onPress(pings.animPlayRest):key(restBind)

-- Keybind updater
function events.TICK()
	
	local restKey = setRestKey:getKey()
	if restKey ~= restBind then
		restBind = restKey
		config:save("AnimRestKeybind", restKey)
	end
	
end

-- Table setup
local t = {}

-- Action
t.restAct = action_wheel:newAction()
	:item(itemCheck("black_bed"))
	:onLeftClick(pings.animPlayRest)

-- Update action
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		t.restAct
			:title(toJson(
				{text = "Play Rest animation", bold = true, color = c.primary}
			))
		
		for _, act in pairs(t) do
			act:hoverColor(c.hover)
		end
		
	end
	
end

-- Returns action
return t