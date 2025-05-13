-- ~/.hammerspoon/dockAuto.lua
local M = {}

local spaces    = hs.spaces
local wf        = hs.window.filter
local timer     = hs.timer
local osascript = hs.osascript
local log       = hs.logger.new("dockAuto", "info")

-- helper: set Dock autohide ON/OFF via AppleScript
local function setDockHidden(hidden)
  local script = string.format([[
    tell application "System Events"
      set autohide of dock preferences to %s
    end tell
  ]], hidden and "true" or "false")
  local ok, err = osascript.applescript(script)
  if not ok then
    log.e("Failed to set Dock autohide: %s", err)
  end
end

-- find the largest standard window in the front Space
local function largestWindowInSpace()
  local sid = spaces.focusedSpace()
  if not sid then return end
  local best, bestArea = nil, 0
  for _, id in ipairs(spaces.windowsForSpace(sid) or {}) do
    local w = hs.window.get(id)
    if w and w:isStandard() and w:isVisible() and not w:isMinimized() then
      local f = w:frame()
      local area = f.w * f.h
      if area > bestArea then best, bestArea = w, area end
    end
  end
  return best
end

-- main evaluation function with debounce/maximize timers
local debounceTimer, maximizeTimer
function M.evaluate()
  if debounceTimer then debounceTimer:stop() end
  debounceTimer = timer.doAfter(0.15, function()
    local w = largestWindowInSpace()
    if maximizeTimer then maximizeTimer:stop() end
    if w then
      local full = w:screen():fullFrame()
      local f, thW, thH = w:frame(), full.w * .8, full.h * .8
      if f.w >= thW and f.h >= thH then
        setDockHidden(true)
        local winID = w:id()
        maximizeTimer = timer.doAfter(0.15, function()
          local win = hs.window.get(winID)
          if win and win:isStandard() then win:maximize() end
        end)
      else
        setDockHidden(false)
      end
    else
      setDockHidden(false)
    end
    debounceTimer = nil
  end)
end

-- set up watchers
function M.start()
  -- Spaces watcher
  hs.spaces.watcher.new(M.evaluate):start()

  -- Window events in current Space
  local watch = wf.new():setDefaultFilter{}:setCurrentSpace(true)
  for _, ev in ipairs({
    wf.windowCreated, wf.windowDestroyed, wf.windowMinimized,
    wf.windowUnminimized, wf.windowMoved, wf.windowFocused,
  }) do
    watch:subscribe(ev, M.evaluate)
  end

  -- initial run
  M.evaluate()
end

return M
