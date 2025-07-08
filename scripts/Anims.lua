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
local idleStyle = config:load("AnimsIdle") or 1

-- Ground idles table
local idles = {
	anims.groundIdle2,
	anims.groundIdle1,
	anims.flying
}

-- Reset IdleStyle if its out of range
if idleStyle > #idles then idleStyle = 1 end

-- Variables
local restData = 0
local isRest = false
local canRest = false

-- Table setup
v = {}

-- Animation variables
v.snap = 0
v.head = vec(0, 0, 0)

-- Parrot pivots
local parrots = {
	
	parts.group.LeftParrotPivot,
	parts.group.RightParrotPivot
	
}

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getTrueRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

function events.TICK()
	
	-- Variables
	local pos = player:getPos()
	local vel = player:getVelocity()
	local onGround = ground()
	local block, hitPos = raycast:block(pos, pos + vec(0, 10, 0))
	
	-- Origins power
	restData = origins.getPowerData(player, "battaur:ceiling_snoozer_toggle") or 0
	
	-- Animation action
	canRest = vel:length() < 0.05 and not block:isAir()
	
	-- Stop rest animation
	if not canRest then
		isRest = false
	end
	
	-- Animation states
	local resting = restData == 1 or isRest
	local flyIdle = idles[idleStyle] == anims.flying and not (pose.swim or pose.sleep or resting)
	local flying = (flyIdle and onGround) or (not onGround or effects.cF) and not (pose.swim or pose.elytra or resting)
	local flapping = flying or (pose.swim and not pose.crawl) or pose.elytra
	local groundIdle = flying and flyIdle or onGround and not (pose.swim or pose.crawl or pose.sleep or effects.cF or resting)
	local groundWalk = (groundIdle or pose.crawl) and vel:length() ~= 0 and not flyIdle
	local sleep = pose.sleep
	
	-- Reset idle anims
	for i, anim in ipairs(idles) do
		if anim:isPlaying() and i ~= idleStyle and not (anim == anims.flying and flying) then
			anim:stop()
		end
	end
	
	-- Animations
	anims.flying:playing(flying)
	anims.flap:playing(flapping)
	idles[idleStyle]:playing(groundIdle)
	anims.groundWalk:playing(groundWalk)
	anims.resting:playing(resting)
	anims.sleep:playing(sleep)
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local vel = player:getVelocity(delta)
	local dir = player:getLookDir()
	
	-- Directional velocity
	local fbVel = player:getVelocity():dot((dir.x_z):normalize())
	local lrVel = player:getVelocity():cross(dir.x_z:normalize()).y
	
	-- Animation speeds
	anims.flap:speed((pose.elytra and math.clamp(1 - vel:length() / 2, 0, 1) or pose.swim and math.clamp(vel:length() * 4, 0, 1) or 1) * (player:isInWater() and 0.5 or 1))
	anims.groundWalk:speed(math.clamp(fbVel < -0.05 and math.min(fbVel, math.abs(lrVel)) * 4 or math.max(fbVel, math.abs(lrVel)) * 4, -2, 2))
	
	-- Animation blend
	anims.flap:blend(pose.elytra and math.clamp(1 - vel:length() / 2, 0, 1) or 1)
	
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
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - vanilla_model.BODY:getOriginRot())
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
	{ anim = anims.flap,        ticks = {3,7}   },
	{ anim = anims.groundIdle1, ticks = {7,7}   },
	{ anim = anims.groundIdle2, ticks = {7,7}   },
	{ anim = anims.groundWalk,  ticks = {3,7}   },
	{ anim = anims.resting,     ticks = {20,20} },
	{ anim = anims.sleep,       ticks = {20,0}  }
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
function pings.setIdleStyle(i)
	
	idleStyle = ((idleStyle + i - 1) % #idles) + 1
	config:save("AnimsIdle", idleStyle)
	
end

-- Sync variables
function pings.syncAnims(a, b)
	
	isRest    = a
	idleStyle = b
	
end

-- Host only instructions
if not host:isHost() then return end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncAnims(isRest, idleStyle)
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

-- Required script
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Check for if page already exists
local pageExists = action_wheel:getPage("Anims")

-- Pages
local parentPage = action_wheel:getPage("Main")
local animsPage  = pageExists or action_wheel:newPage("Anims")

-- Actions table setup
local a = {}

-- Actions
if not pageExists then
	a.pageAct = parentPage:newAction()
		:item(itemCheck("jukebox"))
		:onLeftClick(function() wheel:descend(animsPage) end)
end

a.restAct = animsPage:newAction()
	:item(itemCheck("black_bed"))
	:onToggle(pings.animPlayRest)

a.idleAct = animsPage:newAction()
	:item(itemCheck("scaffolding"))
	:onLeftClick(function() pings.setIdleStyle(1) end)
	:onRightClick(function() pings.setIdleStyle(-1) end)
	:onScroll(pings.setIdleStyle)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Animation Settings", bold = true, color = c.primary}
				))
		end
		
		a.restAct
			:title(toJson(
				{
					"",
					{text = "Play Rest animation", bold = true, color = c.primary},
					{text = canRest and "" or "\n\nUnable to rest! Slow down and make sure blocks are above you!", color = "gold"}
				}
			))
			:toggled(isRest)
		
		a.idleAct
			:title(toJson(
				{
					"",
					{text = "Idle Animation Type", bold = true, color = c.primary},
					{text = "\n\nChoose your idle pose/animation from "..#idles.." option"..(#idles == 1 and "" or "s")..".", color = c.secondary},
					{text = #idles > 1 and "\n\nCurrent Pose: " or "", bold = true, color = c.secondary},
					{text = #idles > 1 and idles[idleStyle]:getName():gsub("^%l", string.upper) or ""}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end