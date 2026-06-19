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

-- for the name, come up with a unique identifier; either reverse DNS or a
-- random alphanumeric string are recommended. this will be used across an
-- entire NotITG install to identify the game's saves, so make sure to try and
-- minimize collisions
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

-- creates a new save module using the data given as the default savedata aswell
-- as the save structure. the table passed and returned will then be written to
-- when the save loads, and read from when it saves
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

---@param instant boolean | nil
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

function self.enableAutosave()
  assertInitialized()
  events:on('exit', function()
    if loadedSavedata then
      self.save(true)
    end
  end)
end

return self