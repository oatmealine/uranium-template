local events = require 'uranium.events'
local EventHandler = require 'stdlib.eventhandler'

local self = {}

---@alias InputType
---| 'Left'        # default binds - P1: Left, P2: KP4
---| 'Down'        # default binds - P1: Down, P2: KP2
---| 'Up'          # default binds - P1: Up, P2: KP8
---| 'Right'       # default binds - P1: Right, P2: KP6
---| 'MenuStart'   # default binds - P1: Enter, P2: KPEnter; written in-game as 'Start'. `MenuStart` may sound like a distinct input from a theoretical `Start`, but no such input exists
---| 'Select'      # default binds - P1: RShift, P2: KP0
---| 'Back'        # default binds - P1: Esc, P2: NumLock; doesn't register, as it will cause you to back out of the file
---| 'Coin'        # default binds - P1: F1
---| 'Operator'    # default binds - P1: Insert, Scroll Lock; doesn't register, as it will cause you to back out of the file
---| 'UpLeft'      # default binds - P2: Num7
---| 'UpRight'     # default binds - P2: Num9
---| 'MenuLeft'    # default binds - P1: Delete, P2: KP/
---| 'MenuDown'    # default binds - P1: End, P2: KP+
---| 'MenuUp'      # default binds - P1: Home, P2: KP-
---| 'MenuRight'   # default binds - P1: PgDn, P2: KP*
---| 'ActionLeft'
---| 'ActionDown'
---| 'ActionUp'
---| 'ActionRight'
---| 'Action1'     # default binds - P1: 1
---| 'Action2'     # default binds - P1: 2
---| 'Action3'     # default binds - P1: 3
---| 'Action4'     # default binds - P1: 4
---| 'Action5'     # default binds - P1: 5
---| 'Action6'     # default binds - P1: 6
---| 'Action7'     # default binds - P1: 7
---| 'Action8'     # default binds - P1: 8

local inputTypes = {
  'Left', 'Down', 'Up', 'Right', 'MenuStart', 'Select', 'Back', 'Coin',
  'Operator', 'UpLeft', 'UpRight', 'MenuLeft', 'MenuDown', 'MenuUp',
  'MenuRight', 'ActionLeft', 'ActionDown', 'ActionUp', 'ActionRight', 'Action1',
  'Action2', 'Action3', 'Action4', 'Action5', 'Action6', 'Action7', 'Action8',
}

---@type table<integer, table<InputType, boolean>>
local inputs = {}

for pn = 1, 2 do
  inputs[pn] = {}
  for _, v in pairs(inputTypes) do
    inputs[pn][v] = false
  end
end

-- Checks if an input is currently held down. If `pn` is not provided, players
-- are ignored and it checks if either of the players have the input held down.
---@param i InputType
---@param pn? number
---@return boolean
function self.isDown(i, pn)
  if not pn then
    for plr = 1, 2 do
      if inputs[plr][i] then
        return true
      end
    end
    return false
  else
    return inputs[pn][i]
  end
end

self.events = EventHandler.new('input')

events:on('init', function()
  for pn = 1, 2 do
    local pn = pn
    for _, key in ipairs(inputTypes) do
      local key = key
      _main:addcommand('StepP' .. pn .. key .. 'PressMessage', function()
        self.events:call('press', key, pn)
        self.inputs[pn][key] = true
      end)
      _main:addcommand('StepP' .. pn .. key .. 'LiftMessage', function()
        self.events:call('release', key, pn)
        self.inputs[pn][key] = false
      end)
    end
  end
end)

return self
