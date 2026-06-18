require 'uranium.internal.constants'

local events = require 'uranium.events'
local actors = require 'uranium.actors'
local config = require 'uranium.config'

local uranium = {}

local hasExited = false
local function onExited()
  if hasExited then return end
  hasExited = true
  events:call('exit')
  -- good templates clean up after themselves
  _G.oat = nil
  ---@diagnostic disable-next-line: assign-type-mismatch
  oat = nil
  _main:hidden(1)
  collectgarbage()
end

local function onCommand(self)
  actors.finalize()
  events:call('init')
  --self:SetDrawFunction(function() end)
end

-- runs once during ScreenReadyCommand, before the user code is loaded
-- hides various actors that are placed by the theme
local function hideThemeActors()
  for _, element in ipairs {
    'Overlay', 'Underlay',
    'ScoreP1', 'ScoreP2',
    'LifeP1', 'LifeP2',
    'PlayerOptionsP1', 'PlayerOptionsP2', 'SongOptions',
    'LifeFrame', 'ScoreFrame',
    'DifficultyP1', 'DifficultyP2',
    'BPMDisplay',
    'MemoryCardDisplayP1', 'MemoryCardDisplayP2'
  } do
    local child = SCREENMAN(element)
    if child then child:hidden(1) end
  end
end

GAMESTATE:ApplyModifiers('clearall')

local t = 0
local lastT = 0

local errored = false
local firstRun = true
local playersLoaded = false

local function update()
  if errored or hasExited then return end
  errored = true

  local P1, P2 = SCREENMAN('PlayerP1'), SCREENMAN('PlayerP2')
  if P1 and P2 then
    playersLoaded = true
  end
  if playersLoaded and not P1 and not P2 then -- sora exit hack
    onExited()
  end

  local newT = os.clock()
  local dt = newT - lastT
  dt = math.max(dt, 0)
  lastT = newT

  if firstRun then
    firstRun = false
    dt = 0
    events:call('ready')
  end

  t = t + dt

  events:call('update', dt)

  errored = false
end

---@param self ActorFrame
local function screenReadyCommand(self)
  actors.finalize()

  if config.hideThemeActors then
    hideThemeActors()
  end

  self:hidden(0)
  --self:addcommand('Update', update)
  --self:luaeffect('Update')
  self:SetDrawFunction(update)
  update()
end

uranium.release = require 'uranium.internal.release'

uranium.ctx = actors.Context.new()

-- as a hack to prevent infinite loops if this is loaded again from the user's
-- code
oat.package.loaded['uranium'] = uranium

require('main')

print('---')

actors.ready(uranium.ctx)

_main:addcommand('On', onCommand)
_main:addcommand('Ready', screenReadyCommand)
_main:addcommand('Off', function() onExited() end)
_main:addcommand('SaltyReset', function() onExited() end)
_main:addcommand('WindowFocus', function()
  events:call('focus', true)
end)
_main:addcommand('WindowFocusLost', function()
  events:call('focus', false)
end)
_main:queuecommand('Ready')

return uranium