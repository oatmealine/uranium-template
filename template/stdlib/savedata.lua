local self = {}

local EventHandler = require 'stdlib.eventhandler'
local binser = require 'stdlib.binser'
local events = require 'uranium.events'

local savedataName
local savedata = {
  _lastSave = {0, 0, 0, 0, 0}
}
local loadedSavedata = false

self.saveNextFrame = false

-- Initializes the save module that'll be used across this entire file.
--
-- For the name, come up with a unique identifier; either reverse DNS or a
-- random alphanumeric string are recommended. This will be used across an
-- entire NotITG install to identify the game's saves, so make sure to try and
-- minimize collisions.
---@param name string
function self.init(name)
  if loadedSavedata then
    error('uranium: cannot initialize savedata module after uranium.init!', 2)
  end
  savedataName = name
end

local function assertInitialized()
  if not savedataName then
    error('uranium: savedata not initialized! please run savedata.init first', 3)
  end
end

-- Creates a new module in your savedata. It uses the table passed into `data`
-- for defaults and structure of the save (also returning it for convenience),
-- then uses it for writing savedata to it and reading savedata from it. Do not
-- re-define the table, as that'll make a table with a different pointer,
-- therefore disconnecting it from the module.
--
-- ```lua
-- local counter = savedata.s({
--   n = 0
-- })
--
-- events:on('init', function()
--   print(counter.n) --> 0, or something else if the saved data differs from the default
-- end)
--
-- events:on('update', function()
--   counter.n = counter.n + 1 -- this will be saved the next time savedata.save is called
-- end)
-- ```
--
-- By default, the name that's used for your module will be path to the Lua file
-- this function is called from, relative to the modfile root. **This means you
-- should not rely on the automatic name generation if you're calling this
-- function twice in the same file, or calling this function via `loadstring` or
-- similar** as it will create unpredictable module names that will change
-- between setups or overlap with other module names.
-- 
-- You can pass in any string you like to `name`, as long as it's unique in your
-- project, to override this behavior.
---@generic T: table
---@param data T
---@param name? string @ defaults to the filepath of the file where this function is called
---@return T
function self.s(data, name)
  if not name then
    name = string.sub(debug.getinfo(2, 'S').source, #('@' .. package.base) + 1)
  end
  assertInitialized()
  if loadedSavedata then
    error('uranium: cannot add new savedata after initializing!', 3)
  end
  if string.sub(name, 1, 1) == '_' then
    error('uranium: cannot start savedata name with an underscore', 2)
  end
  savedata[name] = data
  return data
end

--- prefers tab1 with type mismatches; prefers tab2 with value mismatches
local function mergeTable(tab1, tab2)
  local tab = {}
  for k, v1 in pairs(tab1) do
    local v2 = tab2[k]
    if type(v1) ~= type(v2) then
      tab[k] = v1
    else
      if type(v1) == 'table' then
        tab[k] = mergeTable(v1, v2)
      else
        tab[k] = v2
      end
    end
  end
  return tab
end

-- replaces tab1 with tab2, preserving pointers
local function replaceFromRoot(tab1, tab2)
  for k in pairs(tab2) do
    if type(tab1[k]) == type(tab2[k]) and type(tab1[k]) == 'table' then
      replaceFromRoot(tab1[k], tab2[k])
    else
      tab1[k] = tab2[k]
    end
  end
end

-- Loads the savedata. _Shouldn't be called manually; this is automatically
-- called on `init()`.
function self.load()
  assertInitialized()
  --print('loading...')
  local profile = PROFILEMAN:GetMachineProfile():GetSaved()
  local save = {}
  local serialized = profile[savedataName]

  if not serialized then
    --print('no savedata found')
    save = savedata
  else
    local ok
    ok, save = pcall(binser.deserializeN, serialized, 1)
    if not ok then
      save = savedata
    end
  end

  local newSavedata = mergeTable(savedata, save)
  replaceFromRoot(savedata, newSavedata)
end

self.events = EventHandler.new()

-- Saves the savedata onto the user's profile. It waits a single tick to do so
-- and sets the boolean `saveNextFrame` to `true`; this is so that your game can
-- display a loading frame for the temporary lagspike, as chances are, on
-- lower-end setups with hard drives or exceptionally large profiles, this will
-- momentarily freeze the game as it writes the profile. You can make it
-- instantly save with `instant`.
---@param instant? boolean
function self.save(instant)
  assertInitialized()
  local profile = PROFILEMAN:GetMachineProfile():GetSaved()
  savedata._lastSave = {Hour(), Minute(), DayOfMonth(), MonthOfYear(), Year()}
  local serialized = binser.serialize(savedata)
  profile[savedataName] = serialized

  self.events:call('save')
  if instant then
    PROFILEMAN:SaveMachineProfile()
    self.events:call('saveFinished')
  else
    self.saveNextFrame = true
  end
end

events:on('update', function()
  if self.saveNextFrame then
    self.saveNextFrame = false
    PROFILEMAN:SaveMachineProfile()
    self.events:call('saveFinished')
  end
end)

-- Gets the last save time that persists between game restarts in the format
-- `{hour, minute, date, month, year}`. If the game has not saved once, returns
-- `nil`.
function self.getLastSave()
  assertInitialized()
  if savedata._lastSave and savedata._lastSave[1] == 0 and savedata._lastSave[2] == 0 and savedata._lastSave[3] == 0 and savedata._lastSave[4] == 0 and savedata._lastSave[5] == 0 then
    return nil
  else
    return savedata._lastSave
  end
end

events:on('init', function()
  loadedSavedata = true
  if savedataName then
    self.load()
  end
end)

-- Enables autosave via the `exit` event. Should hopefully mean data should
-- never get lost, but the event is pretty patchy due to engine limitations, so
-- this is wishful thinking at best.
function self.enableAutosave()
  assertInitialized()
  events:on('exit', function()
    if loadedSavedata then
      self.save(true)
    end
  end)
end

return self