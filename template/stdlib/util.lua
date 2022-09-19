---@param a number
---@param b number
---@param x number
---@return number
function mix(a, b, x)
  return a * (1 - x) + b * x
end
lerp = mix

---@param x number
---@return number
function sign(x)
  if x > 0 then return 1 end
  if x < 0 then return -1 end
  return 0
end

function deepcopy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do res[deepcopy(k)] = deepcopy(v) end
  return res
end

---@param a number
---@param x number
---@param y number
---@return number
function clamp(a, x, y)
  return math.max(math.min(a, math.max(x, y)), math.min(x, y))
end

---@param tab any[]
---@param elem any
function includes(tab, elem)
  if not tab then error('bad argument #1 (expected table, got nil)', 2) end
  for _, v in pairs(tab) do
    if elem == v then return true end
  end
  return false
end

---@param text string
---@param length int
function truncate(text, length)
  local addellipses = false

  local firstLine = nil
  for line in string.gfind(text, '([^\n]*)\n?') do
    if not firstLine then
      firstLine = line
    elseif line ~= '' then
      addellipses = true
      break
    end
  end

  text = firstLine
  if string.len(text) > length then
    text = string.sub(text, 1, length)
    addellipses = true
  end

  if addellipses then text = text .. '...' end
  return text
end

function padLeft(str, num, fill)
  local s = {}
  for i = 1, num - #str do
    table.insert(s, fill)
  end
  table.insert(s, str)
  return table.concat(s, '')
end

function padLeft(str, num, fill)
  local s = {}
  table.insert(s, str)
  for i = 1, num - #str do
    table.insert(s, fill)
  end
  return table.concat(s, '')
end

local whitespaces = {' ', '\n', '\r'}

---@param str string
function trimLeft(str)
  while includes(whitespaces, string.sub(str, 1, 1)) do
    str = string.sub(str, 2)
  end
  return str
end

---@param str string
function trimRight(str)
  while includes(whitespaces, string.sub(str, -1, -1)) do
    str = string.sub(str, 1, -2)
  end
  return str
end

---@param str string
function trim(str)
  return trimRight(trimLeft(str))
end

---@param o any
---@return string
--- stringify an object
function fullDump(o, r)
  if type(o) == 'table' and (not r or r > 0) then
    local s = '{'
    local first = true
    for k,v in pairs(o) do
      if not first then
        s = s .. ', '
      end
      local nr = nil
      if r then
        nr = r - 1
      end
      if type(k) ~= 'number' then
        s = s .. tostring(k) .. ' = ' .. fullDump(v, nr)
      else
        s = s .. fullDump(v, nr)
      end
      first = false
    end
    return s .. '}'
  elseif type(o) == 'string' then
    return '"' .. o .. '"'
  else
    return tostring(o)
  end
end

---@param t1 any[]
---@param t2 any[]
---@return any[]
function tableConcat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

---@param tab table
function clearMetatables(tab)
  setmetatable(tab, nil)
  for _, obj in pairs(tab) do
    if type(obj) == 'table' then
      clearMetatables(obj)
    end
  end
end