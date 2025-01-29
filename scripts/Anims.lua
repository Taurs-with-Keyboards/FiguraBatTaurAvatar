-- Required scripts
--require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local origins = require("lib.OriginsAPI")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.BatTaur

-- Variable
local isRest = false

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
	
	-- Animation state
	local rest = restData == 1 or (isRest and vel:length() == 0 and not block:isAir())
	
	-- Animations
	anims.resting:playing(rest)
	
end

function events.RENDER(delta, context)
	
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