-- Required scripts
local parts   = require("lib.PartsAPI")
local ground  = require("lib.GroundCheck")
local effects = require("scripts.SyncedVariables")

-- Parts setup
local bat = parts.new(models.BatTaur)

-- Find all ground parts
local groundParts = bat:createTable(function(part) return part:getName():find("Ground") end)

-- Stop script if ground parts could not be found
if #groundParts == 0 then return end

-- Setup wasGround table
local wasGround = {}
for i = 1, #groundParts do
	wasGround[i] = true
end

-- Play footstep sound
local function playFootstep(p, b)
	
	-- Snow check
	local snow = false
	if world.getBlockState(p + vec(0, 1, 0)):getID() == "minecraft:snow" then
		b = world.getBlockState(p + vec(0, 1, 0))
		snow = true
	end
	
	-- Play sound
	sounds:playSound(
		b:getSounds()["step"],
		p,
		snow and 0.5 or 0.15
	)
	
end

-- Box check
local function inBox(pos, box_min, box_max)
	return pos.x >= box_min.x and pos.x <= box_max.x and
		   pos.y >= box_min.y and pos.y <= box_max.y and
		   pos.z >= box_min.z and pos.z <= box_max.z
end

function events.ON_PLAY_SOUND(id, pos, _, _, _, _, path)
	
	-- Don't trigger if the sound was played by Figura (prevent potential infinite loop)
	if not path then return end
	
	-- Don't do anything if the user isn't loaded
	if not player:isLoaded() then return end
	
	-- Make sure the sound is (most likely) played by the user
	if (player:getPos() - pos):length() > 0.05 then return end
	
	-- If sound contains ".step", stop the sound
	if id:find(".step") then
		return true
	end
	
end

function events.TICK()
	
	-- Variables
	local onGround = ground()
	local inWater  = player:isInWater()
	
	-- Play footsteps based on placement
	if onGround and not (inWater or player:getVehicle() or effects.cF) then
		
		for i = 1, #groundParts do
			
			-- Block variables
			local groundPos   = groundParts[i]:partToWorldMatrix():apply()
			local blockPos    = groundPos:copy():floor()
			local groundBlock = world.getBlockState(groundPos)
			local groundBoxes = groundBlock:getCollisionShape()
			
			-- Check for ground
			local grounded = false
			if groundBoxes then
				for b = 1, #groundBoxes do
					local box = groundBoxes[b]
					if inBox(groundPos, blockPos + box[1], blockPos + box[2]) then
						grounded = true
						break
					end
				end
			end
			
			-- Play footstep
			if grounded and not wasGround[i] then
				playFootstep(groundPos, groundBlock)
			end
			
			-- Store last ground
			wasGround[i] = grounded
			
		end
		
	else
		
		-- If conditions aren't met, legs are considered previously on ground
		for i = 1, #groundParts do
			wasGround[i] = true
		end
		
	end
	
end