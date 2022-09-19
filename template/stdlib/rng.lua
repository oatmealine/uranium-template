-- xoshiro128** 1.1 by David Blackman and Sebastiano Vigna (vigna@acm.org) https://prng.di.unimi.it/xoshiro128starstar.c
-- Lua implementation by Jill "oatmealine" Monoids
-- Licensed under CC-BY-SA

local RAND_MAX = 4294967295

---@param x int
---@param k int
local function rotl(x, k)
  return bitop.bor(bitop.lshift(x, k), bitop.rshift(x, (32 - k)))
end

---@param state int[] @array of size 4; will be mutated
local function next(state)
  local result = rotl(state[2] * 5, 7) * 9
  local t = bitop.lshift(state[2], 9)

  state[3] = bitop.bxor(state[3], state[1])
  state[4] = bitop.bxor(state[4], state[2])
  state[2] = bitop.bxor(state[2], state[3])
  state[1] = bitop.bxor(state[1], state[4])

  state[2] = bitop.bxor(state[3], t)

  state[3] = rotl(state[4], 11)

  return result
end

local JUMP = { 0x8764000b, 0xf542d2d3, 0x6fa035c3, 0x77f2db5b }

---@param state int[] @array of size 4; will be mutated
local function jump(state)
	local s0 = 0
	local s1 = 0
	local s2 = 0
	local s3 = 0

  for _, j in ipairs(JUMP) do
    for b = 0, 31 do
      if bitop.band(j, bitop.lshift(1, b)) ~= 0 then
        s0 = bitop.bxor(s0, state[1])
        s1 = bitop.bxor(s1, state[2])
        s2 = bitop.bxor(s2, state[3])
        s3 = bitop.bxor(s3, state[4])
      end
      next(state)
    end
  end

	state[1] = s0
	state[2] = s1
	state[3] = s2
	state[4] = s3
end

local LONG_JUMP = { 0xb523952e, 0x0b6f099f, 0xccf5a0ef, 0x1c580662 }

---@param state int[] @array of size 4; will be mutated
local function long_jump(state)
	local s0 = 0
	local s1 = 0
	local s2 = 0
	local s3 = 0

  for _, j in ipairs(LONG_JUMP) do
    for b = 0, 31 do
      if bitop.band(j, bitop.lshift(1, b)) ~= 0 then
        s0 = bitop.bxor(s0, state[1])
        s1 = bitop.bxor(s1, state[2])
        s2 = bitop.bxor(s2, state[3])
        s3 = bitop.bxor(s3, state[4])
      end
      next(state)
    end
  end

	state[1] = s0
	state[2] = s1
	state[3] = s2
	state[4] = s3
end

---@class rng a xoshiro128** pseudorandom implementation
---@field public state int[] the current state, size of 4
rng = {}

--- gets the next pseudo-random value; recommended to use abstractions (like __call) over this
---@return int
function rng:next()
  return next(self.state)
end

--- This is the jump function for the generator. It is equivalent
--- to 2^64 calls to next(); it can be used to generate 2^64
--- non-overlapping subsequences for parallel computations.
---@return void
function rng:jump()
  return jump(self.state)
end

--- This is the long-jump function for the generator. It is equivalent to
--- 2^96 calls to next(); it can be used to generate 2^32 starting points,
--- from each of which jump() will generate 2^32 non-overlapping
--- subsequences for parallel distributed computations.
---@return void
function rng:longJump()
  return long_jump(self.state)
end

--- if `max` is not given, `min` will be used as the maximum and the minimum will be 1
--- if min is 1 and max is 4, the returned value can be 1, 2, 3 or 4
---@param min int
---@param max int
---@return int
function rng:int(min, max)
  if not max then
    local m = min
    min = 1
    max = m
  end

  local _min = min
  local _max = max
  min = math.min(_min, _max)
  max = math.max(_min, _max)

  return min + (self:next() % (max - min + 1))
end

--- if `max` is not given, it will be 1
---@param max float
---@return float
function rng:float(max)
  return ((self:next() % RAND_MAX) / RAND_MAX) * (max or 1)
end


---@return boolean
function rng:bool()
  return self:next() % 2 == 0
end

function rng:seed(seed)
  self.state = {seed, seed, seed, seed}
  self:next()
end

local rngmeta = {}

--- acts identical to math.random()
function rngmeta:__call(a, b)
  if a then
    return self:int(a, b)
  end
  return self:float()
end

rngmeta.__index = rng

--- creates a new RNG object
---@param seed int[] @array of size 4, will default to os.time() if not given
---@return rng
function rng.init(seed)
  seed = seed or os.time()
  local state = {seed, seed, seed, seed}
  local this = setmetatable({state = state}, rngmeta)
  this:next() -- just to prevent the state from being all the same number; i dont know a cleaner way of doing this
  return this
end

return rng