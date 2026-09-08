-- Avatar color
avatar:color(vectors.hexToRGB("#5F5046"))

-- Glowing outline
renderer:outlineColor(vectors.hexToRGB("#5F5046"))

-- Host only instructions
if not host:isHost() then return end

-- Table setup
local colors = {}

-- Action variables
colors.hover     = vectors.hexToRGB("#5F5046")
colors.active    = vectors.hexToRGB("#43372F")
colors.primary   = "#5F5046"
colors.secondary = "#43372F"

-- Return variables
return colors