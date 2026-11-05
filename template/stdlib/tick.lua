require 'stdlib.ease'

---@class Tick
---@field time number
---@field locked boolean
---@field private funcs { time: number, func: function, funcArgs: any[] }[] @one-time events
---@field private perframes { time: number, dur: number, func: fun(time: number, a: number) }[] @recurring, temporary events
---@field private perframesActive { time: number, dur: number, func: fun(time: number, a: number) }[]
---@field private eases { time: number, dur: number, ease: (fun(a: number): number), from: number, to: number, func: fun(a: number) }[] @recurring events with a value and easing function
---@field private easesActive { time: number, dur: number, ease: (fun(a: number): number), from: number, to: number, func: fun(a: number) }[]
---@field private auxEases { time: number, dur: number, ease: (fun(a: number): number), aux: Aux, value: number, add: boolean, transient: boolean }[] @mirin-like easing events, used with :aux()
---@field private auxEasesActive { time: number, dur: number, ease: (fun(a: number): number), aux: Aux, value: number, add: boolean, transient: boolean }[]
local Tick = {}

Tick.__index = Tick

--[[
  -- scraps
  local quad = ctx:Quad()
  tick:easeActor(0, 5, outSine, quad, 'x', 500)
  tick:ease(0, 5, outSine, 0, 500, function(x) quad:x(x) end)

  -- this is what i want
  local aux = tick:aux(0) -- 0 as default
  aux:ease(0, 5, outSine, 500)
  -- in a drawfunction
  quad:x(aux.value)
]]

local function insertSorted(tab, value)
  for i, cmp in ipairs(tab) do
    if cmp.time > value.time then
      table.insert(tab, i, value)
      break
    end
  end
  table.insert(tab, value)
end

-- Updates the instance, processing whatever functions need to called. You can
-- technically use any unit as the deltatime, like beats or frames; but your
-- scheduled functions will then use those same units aswell.
function Tick:update(dt)
  self.time = self.time + dt

  for i = 1, #self.funcs do
    local f = self.funcs[i]
    if f and self.time >= f.time then
      f.func(unpack(f.funcArgs))
      table.remove(self.funcs, i)
      i = i - 1
    else
      break
    end
  end

  for i = 1, #self.perframes do
    local f = self.perframes[i]
    if f and self.time >= f.time then
      table.remove(self.perframes, i)
      table.insert(self.perframesActive, f)
      i = i - 1
    else
      break
    end
  end

  for i = 1, #self.perframesActive do
    local f = self.perframesActive[i]
    if f and self.time < (f.time + f.dur) then
      f.func(self.time, (self.time - f.time) / f.dur)
    else
      table.remove(self.perframesActive, i)
      i = i - 1
    end
  end

  for i = 1, #self.eases do
    local f = self.eases[i]
    if f and self.time >= f.time then
      table.remove(self.eases, i)
      table.insert(self.easesActive, f)
      i = i - 1
    else
      break
    end
  end

  for i = 1, #self.easesActive do
    local f = self.easesActive[i]
    if not f then break end
    if self.time < (f.time + f.dur) then
      local a = (self.time - f.time) / f.dur
      local b = f.ease(a)
      f.func(f.from * (1 - b) + f.to * b)
    else
      if f.ease(1) >= 0.5 then
        f.func(f.to)
      else
        f.func(f.from)
      end
      table.remove(self.easesActive, i)
      i = i - 1
    end
  end

  ---@type table<Aux, number>
  local auxOffsets = { }

  for i = 1, #self.auxEases do
    local e = self.auxEases[i]
    if e and self.time >= e.time then
      table.remove(self.auxEases, i)
      table.insert(self.auxEasesActive, e)
      i = i - 1

      if not e.transient then
        local old = e.aux.target
        auxOffsets[e.aux] = 0
        if e.add then
          e.aux.target = old + e.value
          --e.value = e.value
        else
          e.aux.target = e.value
          e.value = e.value - old
        end
      end
    else
      break
    end
  end

  for i = 1, #self.auxEasesActive do
    local e = self.auxEasesActive[i]
    if not e then break end
    if self.time < (e.time + e.dur) then
      local a = (self.time - e.time) / e.dur
      local b = e.ease(a)
      if e.transient then
        auxOffsets[e.aux] = (auxOffsets[e.aux] or 0) + e.value * b
      else
        auxOffsets[e.aux] = (auxOffsets[e.aux] or 0) - e.value * (1 - b)
      end
    else
      table.remove(self.auxEasesActive, i)
      i = i - 1
      auxOffsets[e.aux] = auxOffsets[e.aux] or 0
    end
  end

  for aux, offset in pairs(auxOffsets) do
    aux.value = aux.target + offset
  end
end

-- Schedules a function to be called in `delay`. Any extra arguments passed will
-- be passed to the function. If `delay` is 0 or negative, this call will be
-- delayed by a frame.
---@param delay number
---@param func fun(time: number)
function Tick:func(delay, func, ...)
  if self.locked then error('this tick instance is locked, no new functions can be scheduled', 2) end
  insertSorted(self.funcs, {
    time = self.time + delay,
    func = func,
    funcArgs = arg,
  })
end

-- Schedules a function to be repeatedly called every frame in `delay` for
-- `dur`. The current internally stored time of the `Tick` instance will be
-- passed into the function, alongside with the "progress" of the perframe
-- (`time since start` / `dur`).
---@param delay number
---@param dur number
---@param func fun(time: number)
function Tick:perframe(delay, dur, func)
  if self.locked then error('this tick instance is locked, no new functions can be scheduled', 2) end
  insertSorted(self.perframes, {
    time = self.time + delay,
    dur = dur,
    func = func,
  })
end

-- Schedules a function to be repeatedly called every frame in `delay` for
-- `dur`, easing some value from `from` to `to` with the easing function `ease`.
-- The eased value will be passed into the function.
-- 
-- The easing function is some function that takes in `a` from 0.0 to 1.0 and
-- outputs some `b` from 0.0 to 1.0. An easing function that returns `b=0` for
-- an input of `a>=1` is called "transient". The [`ease`](#ease) module has
-- several of these ready for use.
-- 
-- The function is guaranteed to be called once at the end of its lifecycle with
-- 1.0, or 0.0 if the easing function is transient.
---@param delay number
---@param dur number
---@param ease fun(a: number): number
---@param from number
---@param to number
---@param func fun(time: number)
function Tick:ease(delay, dur, ease, from, to, func)
  if self.locked then error('this tick instance is locked, no new functions can be scheduled', 2) end
  insertSorted(self.eases, {
    time = self.time + delay,
    dur = dur,
    ease = ease,
    from = from,
    to = to,
    func = func,
  })
end

-- Creates a new `Tick` instance. You'll need to manually update every instance
-- in your `update` event callback.
---@return Tick
function Tick.new()
  return setmetatable({
    time = 0,
    locked = false,

    funcs = { },
    perframes = { },
    perframesActive = { },
    eases = { },
    easesActive = { },

    auxEases = { },
    auxEasesActive = { },
  }, Tick)
end

---@class Aux
---@field value number
---@field tick Tick
---@field target number
local Aux = {}
Aux.__index = Aux

-- Similar to `Tick:ease`, except acting upon this specific value. The `from`
-- value is assumed to be the current value at the time of execution.
---@param delay number
---@param duration number
---@param ease fun(a: number): number
---@param value number
function Aux:ease(delay, duration, ease, value)
  if self.tick.locked then error('this tick instance is locked, no new functions can be scheduled', 2) end
  insertSorted(self.tick.auxEases, {
    time = self.tick.time + delay,
    dur = duration,
    ease = ease,
    aux = self,
    value = value,
    add = false,
    transient = ease(1) < 0.5,
  })
end

-- Similar to `Aux:ease`, except adding to the value instead of setting it to a
-- new value.
---@param delay number
---@param duration number
---@param ease fun(a: number): number
---@param value number
function Aux:add(delay, duration, ease, value)
  if self.tick.locked then error('this tick instance is locked, no new functions can be scheduled', 2) end
  insertSorted(self.tick.auxEases, {
    time = self.tick.time + delay,
    dur = duration,
    ease = ease,
    aux = self,
    value = value,
    add = true,
    transient = ease(1) < 0.5,
  })
end

-- Creates a new `Aux`, which is an arbitrary easable value, acting in sync with
-- the parent `Tick`. If you've used a definemod in Mirin, this is something
-- like that.
---@param default? number
function Tick:aux(default)
  if self.locked then error('this tick instance is locked, no new functions can be scheduled', 2) end
  return setmetatable({
    value = default or 0,
    target = default or 0,
    tick = self,
  }, Aux)
end

-- Locks the `Tick`, preventing any further edits to be made to the scheduled
-- functions. If `callback` is passed, it will be called once every scheduled
-- function lapses.
---@param callback? fun() @ Callback to call upon finishing
function Tick:lock(callback)
  if callback then
    local maxTime = 0

    for _, f in ipairs(self.funcs)           do maxTime = math.max(maxTime, f.time) end
    for _, f in ipairs(self.perframes)       do maxTime = math.max(maxTime, f.time + f.dur) end
    for _, f in ipairs(self.perframesActive) do maxTime = math.max(maxTime, f.time + f.dur) end
    for _, f in ipairs(self.eases)           do maxTime = math.max(maxTime, f.time + f.dur) end
    for _, f in ipairs(self.easesActive)     do maxTime = math.max(maxTime, f.time + f.dur) end
    for _, f in ipairs(self.auxEases)        do maxTime = math.max(maxTime, f.time + f.dur) end
    for _, f in ipairs(self.auxEasesActive)  do maxTime = math.max(maxTime, f.time + f.dur) end

    self:func(maxTime, callback)
  end

  self.locked = true
end

return Tick
