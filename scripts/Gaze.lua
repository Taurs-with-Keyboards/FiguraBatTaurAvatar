-- Required scripts
local gaze  = require("lib.Gaze")
local parts = require("lib.PartsAPI")

-- Animations setup
local anims = animations.BatTaur

-- Gaze setup
local earsGaze = gaze:newGaze()
earsGaze:newAnim(
	anims.horizontalEars,
	anims.verticalEars
)
gaze:unsetPrimary()

-- Gaze config
earsGaze.config.socialInterest = 0
earsGaze.config.soundInterest = 1
earsGaze.config.lookInterval = 10

function events.RENDER()
	
	-- Flips the rotation of the gaze ears when upside down
	local flip = math.map(parts.group.Player:getAnimRot().z, 0, 180, 1, -1)
	anims.horizontalEars:blend(flip)
	anims.verticalEars:blend(flip)
	
end