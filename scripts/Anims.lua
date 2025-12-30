-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local origins = require("lib.OriginsAPI")
local ground  = require("lib.GroundCheck")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.BatTaur

-- Synced variables setup
local idleStyle = sync.add(config:load("AnimsIdle"), 1)
local armsMove  = sync.add(config:load("ArmsMove"), false)
local isRest    = sync.add(false)

-- Ground idles table
local idles = {
	anims.groundIdle2,
	anims.groundIdle1,
	anims.flying
}

-- Reset IdleStyle if its out of range
if sync[idleStyle] > #idles then sync[idleStyle] = 1 end

-- Arms setup
local leftArmLerp  = lerp:new(sync[armsMove] and 1 or 0, 0.5)
local rightArmLerp = lerp:new(sync[armsMove] and 1 or 0, 0.5)

-- Gets the origin rotation of a part, clamped
local function getOriginRot(part, delta)
	
	return (vanilla_model[part]:getOriginRot(delta) + 180) % 360 - 180
	
end

-- Variables
local restData = 0
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
		sync[isRest] = false
	end
	
	-- Animation states
	local resting = restData == 1 or sync[isRest]
	local flyIdle = idles[sync[idleStyle]] == anims.flying and not (pose.swim or pose.sleep or resting)
	local flying = (flyIdle and onGround) or (not onGround or effects.cF) and not (pose.swim or pose.elytra or resting)
	local flapping = flying or (pose.swim and not pose.crawl) or pose.elytra
	local groundIdle = flying and flyIdle or onGround and not (pose.swim or pose.crawl or pose.sleep or effects.cF or resting)
	local groundWalk = (groundIdle or pose.crawl) and vel:length() ~= 0 and not flyIdle
	local sleep = pose.sleep
	
	-- Reset idle anims
	for i, anim in ipairs(idles) do
		if anim:isPlaying() and i ~= sync[idleStyle] and not (anim == anims.flying and flying) then
			anim:stop()
		end
	end
	
	-- Animations
	anims.flying:playing(flying)
	anims.flap:playing(flapping)
	idles[sync[idleStyle]]:playing(groundIdle)
	anims.groundWalk:playing(groundWalk)
	anims.resting:playing(resting)
	anims.sleep:playing(sleep)
	
	-- Arm variables
	local handedness = player:isLeftHanded()
	local mainL = not handedness and "OFF_HAND" or "MAIN_HAND"
	local mainR = handedness and "OFF_HAND" or "MAIN_HAND"
	local swingL = player:getSwingArm() == mainL
	local swingR = player:getSwingArm() == mainR
	local using = player:isUsingItem()
	local active = player:getActiveHand()
	local itemL = player:getHeldItem(not handedness)
	local itemR = player:getHeldItem(handedness)
	local usingL = using and active == mainL and itemL:getUseAction()
	local usingR = using and active == mainR and itemR:getUseAction()
	local bow = (usingL or usingR or ""):find("BOW") or (itemL:getTag().Charged or itemR:getTag().Charged) == 1
	
	-- Arms movement override
	local armShouldMove = pose.swim or pose.crawl or pose.climb
	
	-- Arms movement targets
	leftArmLerp.target  = (sync[armsMove] or armShouldMove or swingL or usingL or bow) and 0 or -1
	rightArmLerp.target = (sync[armsMove] or armShouldMove or swingR or usingR or bow) and 0 or -1
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local vel = player:getVelocity()
	local yaw = player:getBodyYaw()
	local dir = vec(math.sin(math.rad(-yaw)), 0, math.cos(math.rad(-yaw)))
	
	-- Directional velocity
	local fbVel = vel:dot((dir.x_z):normalized())
	local lrVel = vel:crossed(dir.x_z:normalized()).y
	local udVel = vel.y
	
	-- Animation speeds
	anims.flap:speed((pose.elytra and math.clamp(1 - vel:length() / 2, 0, 1) or pose.swim and math.clamp(vel:length() * 4, 0, 1) or 1) * (player:isInWater() and 0.5 or 1))
	anims.groundWalk:speed(math.clamp(fbVel * 4, -2, 2))
	
	-- Animation blend
	anims.flap:blend(pose.elytra and math.clamp(1 - vel:length() / 2, 0, 1) or 1)
	
	-- Resting variables
	if restData == 1 or sync[isRest] then
		
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
		v.head = getOriginRot("HEAD", delta) * 2
		
	end
	
	-- Arm idle rotation
	local idleTimer = world.getTime(delta)
	local idleRot   = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	
	-- Apply arm rotations
	parts.group.LeftArm:offsetRot((getOriginRot("LEFT_ARM", delta) + idleRot) * leftArmLerp.currPos)
	parts.group.RightArm:offsetRot((getOriginRot("RIGHT_ARM", delta) - idleRot) * rightArmLerp.currPos)
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - getOriginRot("BODY", delta))
	end
	
	-- Crouch offset
	local bodyRot = getOriginRot("BODY", delta)
	local crouchPos = vec(0, -math.sin(math.rad(bodyRot.x)) * 2, -math.sin(math.rad(bodyRot.x)) * 12)
	parts.group.Player:pos(crouchPos._y_)
	parts.group.UpperBody:offsetPivot(crouchPos):pos(crouchPos.xy_ * 2)
	parts.group.LowerBody:pos(crouchPos)
	
	-- Spyglass rotations
	local headRot = getOriginRot("HEAD", delta)
	headRot.x = math.clamp(headRot.x, -90, 30)
	parts.group.Spyglass:offsetRot(headRot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
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

-- Toggle rest anim
function pings.animPlayRest(boolean)
	
	sync[isRest] = boolean
	
end

-- Idle stance selector
function pings.setIdleStyle(i)
	
	sync[idleStyle] = ((sync[idleStyle] + i - 1) % #idles) + 1
	config:save("AnimsIdle", sync[idleStyle])
	
end

-- Arm movement toggle
function pings.setAnimsArmsMove(boolean)
	
	sync[armsMove] = boolean
	config:save("ArmsMove", sync[armsMove])
	
end

-- Host only instructions
if not host:isHost() then return end

-- Keybinds
local restKeybind = keybinds:newKeybind("Rest Animation", "key.keyboard.keypad.1")
	:onPress(function() pings.animPlayRest(not sync[isRest]) end)

-- Sync config keybinds
sync.keybind(restKeybind, "AnimRestKeybind")

-- Required script
local s, wheel, c = pcall(require, "scripts.ActionWheel")
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
		:item("jukebox")
		:onLeftClick(function() wheel:descend(animsPage) end)
end

a.restAct = animsPage:newAction()
	:item("black_bed")
	:onToggle(pings.animPlayRest)

a.idleAct = animsPage:newAction()
	:item("scaffolding")
	:onLeftClick(function() pings.setIdleStyle(1) end)
	:onRightClick(function() pings.setIdleStyle(-1) end)
	:onScroll(pings.setIdleStyle)

a.armsAct = animsPage:newAction()
	:item("red_dye")
	:toggleItem("rabbit_foot")
	:onToggle(pings.setAnimsArmsMove)
	:toggled(sync[armsMove])

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
			:toggled(sync[isRest])
		
		a.idleAct
			:title(toJson(
				{
					"",
					{text = "Idle Animation Type", bold = true, color = c.primary},
					{text = "\n\nChoose your idle pose/animation from "..#idles.." option"..(#idles == 1 and "" or "s")..".", color = c.secondary},
					{text = #idles > 1 and "\n\nCurrent Pose: " or "", bold = true, color = c.secondary},
					{text = #idles > 1 and idles[sync[idleStyle]]:getName():gsub("^%l", string.upper) or ""}
				}
			))
		
		a.armsAct
			:title(toJson(
				{
					"",
					{text = "Arm Movement Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the movement swing movement of the arms.\nActions are not effected.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end