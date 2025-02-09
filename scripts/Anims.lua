-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local origins = require("lib.OriginsAPI")
local ground  = require("lib.GroundCheck")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.BatTaur

-- Variables
local restData = 0
local isRest = false
local canRest = false

-- Table setup
v = {}

-- Animation variables
v.snap = 0

function events.TICK()
	
	-- Variables
	local pos = player:getPos()
	local vel = player:getVelocity()
	local dir = player:getLookDir()
	local onGround = ground()
	local block, hitPos = raycast:block(pos, pos + vec(0, 10, 0))
	
	-- Directional velocity
	local fbVel = player:getVelocity():dot((dir.x_z):normalize())
	local lrVel = player:getVelocity():cross(dir.x_z:normalize()).y
	
	-- Origins power
	restData = origins.getPowerData(player, "battaur:ceiling_snoozer_toggle") or 0
	
	-- Animation action
	canRest = vel:length() == 0 and not block:isAir()
	
	-- Stop rest animation
	if not canRest then
		isRest = false
	end
	
	-- Animation speeds
	anims.flying:speed(player:isInWater() and 0.5 or 1)
	anims.groundWalk:speed(math.clamp(fbVel < -0.05 and math.min(fbVel, math.abs(lrVel)) * 4 or math.max(fbVel, math.abs(lrVel)) * 4, -2, 2))
	
	-- Animation states
	local flying = (not onGround or effects.cF) and not (restData == 1 or isRest)
	local groundIdle = onGround and not (effects.cF or restData == 1 or isRest)
	local groundWalk = groundIdle and vel:length() ~= 0
	local resting = restData == 1 or isRest
	
	-- Animations
	anims.flying:playing(flying)
	anims.groundIdle:playing(groundIdle)
	anims.groundWalk:playing(groundWalk)
	anims.resting:playing(resting)
	
end

function events.RENDER(delta, context)
	
	-- Resting variables
	if restData == 1 or isRest then
		
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
		v.snap = (hitPos.y - pos.y) * (17 / heightOffset)
		
	end
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.flying,     ticks = {3,7}   },
	{ anim = anims.groundIdle, ticks = {7,7}   },
	{ anim = anims.groundWalk, ticks = {3,7}   },
	{ anim = anims.resting,    ticks = {20,20} }
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
	
	isRest = true
	
end

-- Sync variables
function pings.syncAnims(a)
	
	isRest = a
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local s, c = pcall(require, "scripts.ColorProperties")
if not s then c = {} end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncAnims(isRest)
	end
	
end

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
				{
					"",
					{text = "Play Rest animation", bold = true, color = c.primary},
					{text = canRest and "" or "\n\nUnable to rest! Slow down and make sure blocks are above you!", color = "gold"}
				}
			))
		
		for _, act in pairs(t) do
			act:hoverColor(c.hover)
		end
		
	end
	
end

-- Returns action
return t