-- Avatar color
avatar:color(vectors.hexToRGB("5F5046"))

-- Glowing outline
renderer:outlineColor(vectors.hexToRGB("5F5046"))

-- Host only instructions
if not host:isHost() then return end

-- Table setup
local c = {}

-- Action variables
c.hover     = vectors.hexToRGB("5F5046")
c.active    = vectors.hexToRGB("43372F")
c.primary   = "#5F5046"
c.secondary = "#43372F"

-- Return variables
return c