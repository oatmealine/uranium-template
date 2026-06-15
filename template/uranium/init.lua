require 'uranium.internal.constants'

local events = require 'uranium.events'
local actors = require 'uranium.actors'
local config = require 'uranium.config'

local uranium = {}

local hasExited = false
events:on('exit', function()
  if hasExited then return end
  hasExited = true
  events:call('exit')
  -- good templates clean up after themselves
  _G.oat = nil
  ---@diagnostic disable-next-line: assign-type-mismatch
  oat = nil
  _main:hidden(1)
  collectgarbage()
end)

local function backToSongWheel(message)
  if message then
    SCREENMAN:SystemMessage(message)
    print(message)
  end
  events:call('exit')
  GAMESTATE:FinishSong()
  -- disable update_command
  _main:hidden(1)
end

local function onCommand(self)
  actors.finalize()
  events:call('init')
  _main:SetDrawFunction(function() end)
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
local lastt = GAMESTATE:GetSongTime()
local function screenReadyCommand(self)
  actors.finalize()

  if config.hideThemeActors then
    hideThemeActors()
  end

  self:hidden(0)

  collectgarbage()

  local errored = false
  local firstrun = true
  local playersLoaded = false
  self:addcommand('Update', function()
    if errored then
      return 0
    end
    errored = true

    local P1, P2 = SCREENMAN('PlayerP1'), SCREENMAN('PlayerP2')
    if P1 and P2 then
      playersLoaded = true
    end
    if playersLoaded and not P1 and not P2 then -- sora exit hack
      events:call('exit')
    end

    local newt = os.clock()
    local dt = newt - lastt
    dt = math.max(dt, 0)
    lastt = newt

    if firstrun then
      firstrun = false
      dt = 0
      self:GetChildren()[2]:hidden(1)
      events:call('ready')
    end

    t = t + dt

    events:call('update', dt)

    errored = false

    return 0
  end)
  self:luaeffect('Update')
end

---@class UraniumRelease
---@field branch string
---@field commit string
---@field version string
---@field name string
---@field prettyName string
---@field homeURL string

---@type UraniumRelease
uranium.release = {}

if not pcall(function() uranium.release = require('uranium.internal.release') end) then
  uranium.release = require('uranium.internal.release_blank')
end

uranium.ctx = actors.Context.new()

-- as a hack to prevent infinite loops if this is loaded again from the user's
-- code

oat.package.loaded['uranium'] = uranium

local success, result = pcall(function()
  return require('main')
end)

if success then
  print('---')

  actors.ready(uranium.ctx)

  _main:addcommand('On', onCommand)
  _main:addcommand('Ready', screenReadyCommand)
  _main:addcommand('Off', function() events:call('exit') end)
  _main:addcommand('SaltyReset', function() events:call('exit') end)
  _main:addcommand('WindowFocus', function()
    events:call('focus', true)
  end)
  _main:addcommand('WindowFocusLost', function()
    events:call('focus', false)
  end)
  _main:queuecommand('Ready')
else
  Trace('got an error loading main.lua!')
  Trace(result)
  backToSongWheel('loading .lua file failed, check log for details')
  error('uranium: loading main.lua file failed:\n' .. result)
end

return uranium