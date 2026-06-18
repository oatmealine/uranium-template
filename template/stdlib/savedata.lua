-- TODO replace prints with some logger lib?

local self = {}

local EventHandler = require 'stdlib.eventhandler'
local binser = require 'stdlib.binser'
require('stdlib.util')
local events = require 'uranium.events'

local savedataName
local savedata = {
  _lastSave = {0, 0, 0, 0, 0}
}
local loadedSavedata = false

self.saveNextFrame = false

---@param name string @a unique name for the entire modfile
---@param forceIgnore boolean | nil
--- for picking a name:
--- please head to this link:
--- https://www.random.org/strings/?num=1&len=16&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new
--- and generate yourself a hash. afterwards, append it to your game name like so:
--- savedata.initializeModule('myGameName_doAmaUOBIjiaSWyz')
--- this helps ensure no collisions happen, breaking both of the modfiles in the process!
--- **DON'T CHANGE THIS!!** else you'll break existing saves
function self.initializeModule(name, forceIgnore)
  if loadedSavedata then
    error('uranium: cannot initialize savedata module after uranium.init!', 3)
  end
  if not forceIgnore then
    if #name < 16 then
      error('uranium: savedata name too short! must be at least 16 characters long', 2)
    end

    local normalChars = 0
    local specialChars = 0
    for i = 1, #name do
      local char = string.sub(name, i, i)
      local special = string.lower(char) == string.upper(char)
      if special then
        specialChars = specialChars + 1
      else
        normalChars = normalChars + 1
      end
    end

    if normalChars < 4 then
      error('uranium: savedata name should have at least 4 non-special characters!', 2)
    end
    if specialChars < 2 then
      error('uranium: savedata name should have at least 2 special characters!', 2)
    end
  end

  savedataName = name
end

local function checkIfInitialized()
  if not savedataName then
    error('uranium: savedata not initialized! please run savedata.initializeModule first', 3)
  end
end

local function convertSource(s)
  local pathSplit = split(s.source, '/')
  local lastTwo = pathSplit[#pathSplit - 1] .. '/' .. string.sub(pathSplit[#pathSplit], 1, -5)
  return lastTwo
end

---@param data table
---@param name string | nil
function self.s(data, name)
  if not name then name = convertSource(debug.getinfo(2, 'S')) end
  checkIfInitialized()
  if loadedSavedata then
    error('uranium: cannot add new savedata after initializing!', 3)
  end
  if string.sub(name, 1, 1) == '_' then
    error('uranium: cannot start savedata name with an underscore', 2)
  end
  savedata[name] = data
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

--- replaces tab1 with tab2, preserving pointers
--- this sucks
local function replaceFromRoot(tab1, tab2)
  local keys = {}
  for k in pairs(tab1) do
    if not includes(keys, k) then
      table.insert(keys, k)
    end
  end
  for k in pairs(tab2) do
    if not includes(keys, k) then
      table.insert(keys, k)
    end
  end

  for _, key in ipairs(keys) do
    if type(tab1[key]) == type(tab2[key]) and type(tab1[key]) == 'table' then
      replaceFromRoot(tab1[key], tab2[key])
    else
      tab1[key] = tab2[key]
    end
  end
end

function self.load()
  checkIfInitialized()
  --print('loading...')
  local profile = PROFILEMAN:GetMachineProfile():GetSaved()
  local save = {}
  local serialized = profile[savedataName]

  if not serialized then
    --print('no savedata found')
    save = savedata
  else
    --print('savedata found: ' .. serialized)
    local ok
    ok, save = pcall(binser.deserializeN, serialized, 1)
    if not ok then
      --print('savedata corrupt, reverting to default')
      save = savedata
    else
      --print('deserialized: ' .. fullDump(save))
    end
  end

  local newSavedata = mergeTable(savedata, save)
  replaceFromRoot(savedata, newSavedata)
  --print('merged: ' .. fullDump(savedata))
end

self.events = EventHandler.new()

---@param instant boolean | nil
function self.save(instant)
  checkIfInitialized()
  --print('saving...')
  local profile = PROFILEMAN:GetMachineProfile():GetSaved()
  savedata._lastSave = {Hour(), Minute(), DayOfMonth(), MonthOfYear(), Year()}
  --print('savedata: ' .. fullDump(savedata))
  local serialized = binser.serialize(savedata)
  --print('serialized: ' .. serialized)
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
  checkIfInitialized()
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
  checkIfInitialized()
  events:on('exit', function()
    if loadedSavedata then
      self.save(true)
    end
  end)
end

return self