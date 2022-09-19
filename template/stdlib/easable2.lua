---@class easable2
---@field public a number @the eased value
---@field public toa number @the target, uneased value
---@field public ease fun(a:number):number @the ease to use
---@field protected onUpdateFuncs fun(a:number):nil[]
---@field protected _a number @the internal value, linearly eased
local eas = {}

---@param new number @New value to ease to
---@return void
function eas:set(new)
  self.toa = new
end

---@param new number @New value
---@return void
function eas:reset(new)
  self.toa = new
  self._a = new
end

---@param new number @How much to add to current value to ease to
---@return void
function eas:add(new)
  self.toa = self.toa + new
end

---@param func fun(a: number):void @Adds a callback function that will run each time the eased value changes
---@return void
function eas:onUpdate(func)
  table.insert(self.onUpdateFuncs, func)
end

local easmeta = {}

easmeta.__index = eas
easmeta.__name = 'easable2'

function easmeta.__add(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) + ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__sub(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) - ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__mul(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) * ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__div(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) / ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__mod(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) % ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__eq(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) == ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__lt(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) < ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__le(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) <= ((type(b) == 'table' and b.a) and b.a or b)
end

function easmeta:__call(dt)
  if self._a == self.toa then
    -- do nothing
  elseif self._a < self.toa then
    self._a = self._a + math.min(dt, math.abs(self._a - self.toa))
  else
    self._a = self._a - math.min(dt, math.abs(self._a - self.toa))
  end
  self.a = self.ease(self._a)

  for _, callback in ipairs(self.onUpdateFuncs) do
    callback(self.a)
  end
end
function easmeta:__tostring()
  return tostring(self.a)
end
function easmeta:__unm(self)
  return -self.a
end

---@param default number
---@return easable2
function easable2(default, ease)
  default = default or 0
  return setmetatable({a = default, toa = default, onUpdateFuncs = {}, ease = ease or outSine, _a = default}, easmeta)
end