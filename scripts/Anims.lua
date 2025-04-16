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

-- Config setup
config:name("BatTaur")
local idleStance = config:load("AnimsIdleStance") or 1

-- Ground idles table
local idles = {
	anims.groundIdle2,
	anims.groundIdle1,
	anims.flying
}

-- Reset IdleStance if its out of range
if idleStance > #idles then idleStance = 1 end

-- Variables
local restData = 0
local isRest = false
local canRest = false

-- Table setup
v = {}

-- Animation variables
v.snap = 0
v.head = vec(0, 0, 0)

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
	canRest = vel:length() < 0.05 and not block:isAir()
	
	-- Stop rest animation
	if not canRest then
		isRest = false
	end
	
	-- Animation speeds
	anims.flying:speed(player:isInWater() and 0.5 or 1)
	anims.groundWalk:speed(math.clamp(fbVel < -0.05 and math.min(fbVel, math.abs(lrVel)) * 4 or math.max(fbVel, math.abs(lrVel)) * 4, -2, 2))
	
	-- Animation states
	local resting = restData == 1 or isRest
	local flyIdle = idles[idleStance] == anims.flying and not resting
	local flying = (flyIdle and onGround) or (not onGround or effects.cF) and not resting
	local groundIdle = flying and flyIdle or onGround and not (effects.cF or resting)
	local groundWalk = groundIdle and vel:length() ~= 0 and not flyIdle
	
	-- Reset idle anims
	for i, anim in ipairs(idles) do
		if anim:isPlaying() and i ~= idleStance and not (anim == anims.flying and flying) then
			anim:stop()
		end
	end
	
	-- Animations
	anims.flying:playing(flying)
	idles[idleStance]:playing(groundIdle)
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
		v.head = ((vanilla_model.HEAD:getOriginRot() + 180) % 360 - 180) * 2
		
	end
	
	-- Crouch offset
	local bodyRot = vanilla_model.BODY:getOriginRot(delta)
	local crouchPos = vec(0, -math.sin(math.rad(bodyRot.x)) * 2, -math.sin(math.rad(bodyRot.x)) * 12)
	parts.group.Player:pos(crouchPos._y_)
	parts.group.UpperBody:offsetPivot(crouchPos):pos(crouchPos.xy_ * 2)
	parts.group.LowerBody:pos(crouchPos)
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.flying,      ticks = {3,7}   },
	{ anim = anims.groundIdle1, ticks = {7,7}   },
	{ anim = anims.groundIdle2, ticks = {7,7}   },
	{ anim = anims.groundWalk,  ticks = {3,7}   },
	{ anim = anims.resting,     ticks = {20,20} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	if blend.anim ~= nil then
		blend.anim:blendTime(table.unpack(blend.ticks)):blendCurve("easeOutQuad")
	end
end

-- Fixing spyglass jank
function events.RENDER(delta, context)
	
	local rot = vanilla_model.HEAD:getOriginRot()
	rot.x = math.clamp(rot.x, -90, 30)
	parts.group.Spyglass:offsetRot(rot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end

-- Toggle rest anim
function pings.animPlayRest(boolean)
	
	isRest = boolean
	
end

-- Idle stance selector
function pings.setIdleStance(i)
	
	idleStance = ((idleStance + i - 1) % #idles) + 1
	config:save("AnimsIdleStance", idleStance)
	
end

-- Sync variables
function pings.syncAnims(a, b)
	
	isRest     = a
	idleStance = b
	
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
		pings.syncAnims(isRest, idleStance)
	end
	
end

-- Rest keybind
local restBind   = config:load("AnimRestKeybind") or "key.keyboard.keypad.1"
local setRestKey = keybinds:newKeybind("Rest Animation"):onPress(function() pings.animPlayRest(not isRest) end):key(restBind)

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

-- Actions
t.restAct = action_wheel:newAction()
	:item(itemCheck("black_bed"))
	:onToggle(pings.animPlayRest)

t.idleAct = action_wheel:newAction()
	:item(itemCheck("scaffolding"))
	:onLeftClick(function() pings.setIdleStance(1) end)
	:onRightClick(function() pings.setIdleStance(-1) end)

-- Update actions
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
			:toggled(isRest)
		
		t.idleAct
			:title(toJson(
				{
					"",
					{text = "Idle Animation Type", bold = true, color = c.primary},
					{text = "\n\nChoose your idle pose/animation from "..#idles.." option"..(#idles == 1 and "" or "s")..".", color = c.secondary}
				}
			))
			:toggled(isRest)
		
		for _, act in pairs(t) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end

-- Returns actions
return t