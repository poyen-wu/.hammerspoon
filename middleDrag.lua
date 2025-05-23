-- middleDrag.lua
-- A little module that turns “hold‐middle‐mouse and drag” into scroll.

local obj = {
  scrollButton     = 2,    -- default: button 2 (middle mouse)
  scrollMultiplier = -4,   -- negative for "natural" scroll
}

-- private state
local deferred, oldMousePos
local downTap, upTap, dragTap

-- start listening
function obj:start()
  -- stop any existing taps
  self:stop()

  downTap = hs.eventtap.new(
    { hs.eventtap.event.types.otherMouseDown },
    function(e)
      local btn = e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
      if btn == self.scrollButton then
        deferred = true
        return true   -- swallow the down
      end
      return false
    end
  )

  upTap = hs.eventtap.new(
    { hs.eventtap.event.types.otherMouseUp },
    function(e)
      local btn = e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
      if btn == self.scrollButton then
        if deferred then
          -- if we never dragged, re-emit a click
          downTap:stop()
          upTap:stop()
          hs.eventtap.otherClick(e:location(), btn)
          downTap:start()
          upTap:start()
          return true
        end
        return false
      end
      return false
    end
  )

  dragTap = hs.eventtap.new(
    { hs.eventtap.event.types.otherMouseDragged },
    function(e)
      local btn = e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
      if btn == self.scrollButton then
        -- we're dragging, so treat as scroll
        deferred = false
        oldMousePos = hs.mouse.getAbsolutePosition()

        local dx = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaX)
        local dy = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaY)
        local scrollEvt = hs.eventtap.event.newScrollEvent(
          { -dx * self.scrollMultiplier, dy * self.scrollMultiplier },
          {}, -- no modifiers
          'pixel'
        )

        -- put pointer back
        hs.mouse.setAbsolutePosition(oldMousePos)
        return true, { scrollEvt }
      end
      return false
    end
  )

  downTap:start()
  upTap:start()
  dragTap:start()
end

-- stop listening
function obj:stop()
  if downTap  then downTap:stop();  downTap  = nil end
  if upTap    then upTap:stop();    upTap    = nil end
  if dragTap  then dragTap:stop();  dragTap  = nil end
end

-- optional configuration before :start()
-- params.button     = which otherMouse button to use
-- params.multiplier = scroll multiplier
function obj:configure(params)
  if params.button     then self.scrollButton     = params.button end
  if params.multiplier then self.scrollMultiplier = params.multiplier end
end

return obj
