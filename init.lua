-- ~/.hammerspoon/init.lua
local dockAuto = require "dockAuto"
dockAuto.start()

local middleDrag = require "middleDrag"
middleDrag:configure{
  button     = 2,    -- middle mouse
  multiplier = -4,   -- negative = natural scroll
}

middleDrag:start()
