--
-- actor235 - a portable actor generator used by uranium template
--
local M = {}

local Proxy = require 'uranium.actors.proxy'

-- "configurable" constants

local NODES_PER_AF = 10
local ACTORS_FILENAME = 'actors.xml'
local PATH_PREFIX_SHADER = '../'
local PATH_PREFIX_FILE = '../'
local PATH_PREFIX_FONT = '../'
local ENABLE_LOGGING = false

local function warn(str)
  Debug('[actor235] WARN: ' .. tostring(str))
end

local function print(...)
  if not ENABLE_LOGGING then return end

  local msg = {}
  for _, val in ipairs(arg) do
    table.insert(msg, tostring(val))
  end
  Debug('[actor235] ' .. table.concat(msg, '\t'))
end

--[[
  ====================================
  =         INITIALIZATION           =
  ====================================
]]
-- Low-level actor initialization / loading

local log = NODES_PER_AF == 10
            and math.log10
            or function(n)
              return math.log(n)/math.log(NODES_PER_AF)
            end

---@class AbstractActor
---@field Type string?
---@field File string?
---@field Font string?
---@field Init? fun(self: Actor): nil
---@field Frag string
---@field Vert string
---@class AbstractActorFrame
---@field Type 'ActorFrame'
---@field Children (AbstractActor | AbstractActorFrame)[]
---@field Init? fun(self: Actor): nil

---@class NodeStack
---@field actors (AbstractActor | AbstractActorFrame)[] @ Actors that should be defined in this stack
---@field depth number @ The depth at which actor placement should begin
---@field cd number @ The current actors.xml depth, incremented on recursing into actors.xml and decremented after the last Condition call
---@field actorIdx number @ The current actor's index, referring to `actors` (1-indexed)

local stack = {}

---@param entry NodeStack
function stack:push(entry)
  table.insert(self, entry)
end

---@return NodeStack
function stack:pop()
  local t = self[#self]
  table.remove(self, #self)
  return t
end

---@return NodeStack
function stack:top()
  return self[#self]
end

function stack:clear()
  for i = #self, 1, -1 do
    table.remove(self, i)
  end
end

function stack:log(str)
  print(string.rep('  ', #self) .. tostring(str))
end

local function getMinDepth(t)
  local depth = math.ceil(log(#t))
  return math.max(depth, 1)
end

---@param actors (AbstractActor | AbstractActorFrame)[]
local function pushNewLayer(actors)
  local depth = getMinDepth(actors)

  print('! there are ' .. #actors .. ' actors')
  print('! we should be at depth ' .. getMinDepth(actors))
  print('! which would give us ' .. math.pow(NODES_PER_AF, depth) .. ' slots to fit those actors, in theory')

  stack:push({
    actorIdx = 0, -- start with 0 so Condition can increment it once
    actors = actors,
    depth = depth,
    cd = 1,
  })

  --print('--- new layer ---   z: ' .. #stack)
end

local actorInit = {}

---@type AbstractActor
local currentActor = nil
local actorPlaced = false

---@return AbstractActor
local function getNextActor()
  local s = stack:top()

  if s.cd < s.depth then
    -- recurse
    s.cd = s.cd + 1
    stack:log('s.cd++ (=' .. s.cd .. ')')
    return {
      Type = nil,
      File = ACTORS_FILENAME,
    }
  end

  s.actorIdx = s.actorIdx + 1

  local actor = s.actors[s.actorIdx]

  if actor.Type == 'ActorFrame' then
    -- recurse, push new layer
    pushNewLayer(actor.Children)
    return {
      Type = nil,
      File = ACTORS_FILENAME,
    }
  end

  return actor
end

function actorInit.Condition(hasShader)
  local s = stack:top()

  if not s then
    warn('ready() was not called, and yet actors.xml has been loaded? if it has, the stack is glogged')
    return false
  end

  if s.actorIdx >= #s.actors then
    -- we've placed every actor down, return early
    stack:log('cond: (done, returning early)')
    return false
  end

  if hasShader == false then
    -- first of the element pair, so we grab the current actor here
    currentActor = getNextActor()
    actorPlaced = false
  end

  -- EDGECASE: at the edge between the end of an actorframe and the next actor
  -- in sequence in the parent actorframe, an actor will end up being created
  -- twice because both the last actor in an actorframe and the next after a
  -- non-shader actor will be a shader actor, and actor creation always treats
  -- the two in pairs and doesn't expect to run into two shader actors in a row.
  -- when an actor is placed, actorPlaced is set to true. this is the rare case
  -- in which actorPlaced can be true here, in which case we should assume the
  -- actor here has already been made
  if actorPlaced then
    return
  end

  local needsShader = not not (currentActor.Frag or currentActor.Vert)
  if hasShader ~= needsShader then
    -- only create an actor with frag/vert set if the actor truly needs it
    return
  end

  -- proceed with creation

  print('cond: creating actor idx ' .. s.actorIdx)
  print(s.actors[s.actorIdx] and s.actors[s.actorIdx].File)

  actorPlaced = true

  stack:log('<>')

  return true
end

function actorInit.Type()
  stack:log(' Type ' .. tostring(currentActor.Type))
  return currentActor.Type
end

function actorInit.File()
  stack:log(' File ' .. tostring(currentActor.File))
  return currentActor.File
end

function actorInit.Font()
  stack:log(' Font ' .. tostring(currentActor.Font))
  return currentActor.Font
end

function actorInit.Frag()
  stack:log(' Frag ' .. tostring(currentActor.Frag))
  return currentActor.Frag or 'nop.frag'
end

function actorInit.Vert()
  stack:log(' Vert ' .. tostring(currentActor.Vert))
  return currentActor.Vert or 'nop.vert'
end

---@param idx number @ a number from 1 to NODES_PER_AF, inclusive
function actorInit.Init(idx)
  ---@param self Actor
  return function(self)
    stack:log('</> -> ' .. tostring(self))

    local s = stack:top()

    -- SPECIAL CASE: we must manually clean up actorframes with 0 children
    -- since no InitCommand was called while we were inside of it
    if #s.actors == 0 then
      s.cd = s.cd - 1
      stack:log('s.cd-- (=' .. s.cd .. ')')
    end

    if s.cd == s.depth then
      -- we're at the desired depth to define actors
      local actor = currentActor
      if actor.Init then actor.Init(self) end
    end

    if s.cd < 1 then
      -- we've just exited a layer!
      print('--- layer ' .. #stack .. ' done ---')
      stack:pop()
      s = stack:top()

      if s then
        local actor = s.actors[s.actorIdx]
        if actor.Init then actor.Init(self) end
      end
    end

    if idx >= NODES_PER_AF or (s and s.actorIdx == #s.actors) then
      -- We've reached the end of the current actors.xml, decrement depth
      s.cd = s.cd - 1
      stack:log('s.cd-- (=' .. s.cd .. ')')
    end
  end
end

--[[
  ====================================
  =               DEF                =
  ====================================
]]
-- Defining actors, actor queue

---@class Context
---@field actorQueue ({ proxy: unknown, toXML: fun(): AbstractActor | AbstractActorFrame, subContext: Context? })[]
---@field locked boolean @ If locked, prevents new actors from being defined
local Context = {}

Context.__index = Context

function Context:assertUnlocked()
  if self.locked then
    error('actor235: attempting to modify actor queue while it is locked. did you call \'lock\' too early?', 3)
  end
end
function Context:lock()
  self.locked = true
end
function Context:reset()
  self.actorQueue = {}
  self.locked = false
end

-- Defines a Sprite actor.
---@param file string?
---@return Sprite
function Context:Sprite(file)
  self:assertUnlocked()
  local proxy = Proxy.new('Sprite')
  table.insert(self.actorQueue, {
    proxy = proxy,
    toXML = function()
      return {
        Type = (not file) and 'Sprite' or nil,
        File = file and (PATH_PREFIX_FILE .. file) or nil,
        Init = function(actor)
          Proxy.resolve(proxy, actor)
        end
      }
    end
  })
  return proxy
end

-- Defines a BitmapText actor.
---@param font string? @ Defaults to 'common'
---@param text string? @ String to initialize with
---@return BitmapText
function Context:BitmapText(font, text)
  self:assertUnlocked()
  local proxy = Proxy.new('BitmapText')
  table.insert(self.actorQueue, {
    proxy = proxy,
    toXML = function()
      return {
        Type = 'BitmapText',
        Font = font and (PATH_PREFIX_FONT .. font) or 'common',
        Init = function(actor)
          if text then actor:settext(text) end
          Proxy.resolve(proxy, actor)
        end
      }
    end
  })
  return proxy
end

local function actor0Arg(type)
  return function(self)
    self:assertUnlocked()
    local proxy = Proxy.new(type)
    table.insert(self.actorQueue, {
      proxy = proxy,
      toXML = function()
        return {
          Type = type,
          Init = function(actor)
            Proxy.resolve(proxy, actor)
          end
        }
      end
    })
    return proxy
  end
end
local function actorFileArg(type, useType)
  return function(self, file)
    self:assertUnlocked()
    if not file then
      error('actor235: cannot create ' .. type .. ' a file', 2)
    end
    local proxy = Proxy.new(type)
    table.insert(self.actorQueue, {
      proxy = proxy,
      toXML = function()
        return {
          Type = useType and type or nil,
          File = PATH_PREFIX_FILE .. file,
          Init = function(actor)
            Proxy.resolve(proxy, actor)
          end
        }
      end
    })
    return proxy
  end
end

-- Defines a Quad actor.
---@type fun(ctx: Context): Quad
Context.Quad = actor0Arg('Quad')
-- Defines an ActorProxy actor.
---@type fun(ctx: Context): ActorProxy
Context.ActorProxy = actor0Arg('ActorProxy')
-- Defines a Polygon actor.
---@type fun(ctx: Context): Polygon
Context.Polygon = actor0Arg('Polygon')
-- Defines an ActorFrameTexture actor.
---@type fun(ctx: Context): ActorFrameTexture
Context.ActorFrameTexture = actor0Arg('ActorFrameTexture')
-- Defines a Model actor.
---@type fun(ctx: Context, file: string): Model
Context.Model = actorFileArg('Model', false)
-- Defines an ActorSound actor.
---@type fun(ctx: Context, file: string): ActorSound
Context.ActorSound = actorFileArg('ActorSound', true)

local function isShaderCode(str)
  return string.find(str or '', '\n')
end

-- Defines a shader. `frag` and `vert` can either be filenames or shader code.
---@param frag string | nil
---@param vert string | nil
---@return RageShaderProgram
function Context:Shader(frag, vert)
  self:assertUnlocked()
  local proxy = Proxy.new('RageShaderProgram')

  local fragFile = frag
  local vertFile = vert

  local isFragShaderCode = isShaderCode(frag)
  local isVertShaderCode = isShaderCode(vert)

  if isFragShaderCode then fragFile = nil end
  if isVertShaderCode then vertFile = nil end

  if (frag and vert) and ((isFragShaderCode and not isVertShaderCode) or (not isFragShaderCode and isVertShaderCode)) then
    error('actor235: cannot create a shader with 1 shader file and 1 shader code block', 2)
  end

  table.insert(self.actorQueue, {
    proxy = proxy,
    toXML = function()
      return {
        Type = 'Sprite',
        Frag = fragFile and (PATH_PREFIX_SHADER .. fragFile) or 'nop.frag',
        Vert = vertFile and (PATH_PREFIX_SHADER .. vertFile) or 'nop.vert',
        ---@param actor Sprite
        Init = function(actor)
          actor:hidden(1)
          local shader = actor:GetShader() --[[@as RageShaderProgram]]
          Proxy.resolve(proxy, shader)

          if isFragShaderCode or isVertShaderCode then
            shader:compile(vert or '', frag or '')
          end
        end
      }
    end
  })
  return proxy
end

-- Defines a texture.
---@param file string
---@return RageTexture
function Context:Texture(file)
  self:assertUnlocked()
  if not file then error('actor235: cannot create Texture without a file', 2) end

  local proxy = Proxy.new('RageTexture')

  table.insert(self.actorQueue, {
    proxy = proxy,
    toXML = function()
      return {
        File = file,
        Init = function(actor)
          actor:hidden(1)
          Proxy.resolve(proxy, actor:GetTexture())
        end,
      }
    end,
  })

  return proxy
end

-- Defines an ActorFrame.
---@return ActorFrame
function Context:ActorFrame()
  self:assertUnlocked()

  local proxy = Proxy.new('ActorFrame')
  local subContext = Context.new()
  Proxy.setData(proxy, 'subContext', subContext)

  table.insert(self.actorQueue, {
    proxy = proxy,
    toXML = function()
      return {
        Type = 'ActorFrame',
        Init = function(actor)
          Proxy.resolve(proxy, actor)
        end,
        Children = subContext:toTree(),
      }
    end,
  })

  return proxy
end

-- Creates a Context instance out of an ActorFrame.
-- All actors created under the new Context will be automatically parented
-- to the ActorFrame.
---@param frame ActorFrame
---@return Context
function Context.getContext(frame)
  return Proxy.getData(frame, 'subContext')
end

-- [deprecated, use Context.getContext preferably]
--
-- Adds a child to an ActorFrame. **Please be aware of the side-effects!**
---@param frame ActorFrame
---@param child Actor
function Context:addChild(frame, child)
  if not frame or not child then
    error('actor235: frame and actor must both Exist', 2)
  end
  if self.locked then
    error('actor235: cannot create frame-child associations after actors have been locked', 2)
  end
  if not Proxy.isProxy(frame) then
    error('actor235: ActorFrame passed into addChild must be one instantiated with ActorFrame()!', 2)
  end
  if not Proxy.isProxy(child) then
    error('actor235: actor passed into addChild must be one instantiated w/ actor235', 2)
  end

  -- hacky but it achieves what we need
  local subContext = self.getContext(frame)
  local movedActor
  for i = #self.actorQueue, 1, -1 do
    local actor = self.actorQueue[i]
    if actor.proxy == child then
      movedActor = actor
      table.remove(self.actorQueue, i)
      break
    end
  end
  assert(movedActor, 'actor235: referenced child is not under given Context instance')
  table.insert(subContext.actorQueue, movedActor)
end

---@return (AbstractActor | AbstractActorFrame)[]
function Context:toTree()
  local root = {}

  for _, q in ipairs(self.actorQueue) do
    table.insert(root, q.toXML())
  end

  return root
end

---@return Context
function Context.new()
  return setmetatable({
    actorQueue = {},
    locked = false,
  }, Context)
end

M.Context = Context

--[[
  ====================================
  =              MISC                =
  ====================================
]]
-- APIs, conveniences, etc

local function prettyPrintTree(tree, depth)
  depth = depth or 0
  for _, actor in ipairs(tree) do
    if actor.Type == 'ActorFrame' then
      print(string.rep('  ', depth) .. '<ActorFrame><children>')
      prettyPrintTree(actor.Children, depth + 1)
      print(string.rep('  ', depth) .. '</children></ActorFrame>')
    else
      local str = '<Layer'
      for k, v in pairs(actor) do
        str = str .. ' ' .. k .. '="' .. tostring(v) .. '"'
      end
      str = str .. '/>'

      print(string.rep('  ', depth) .. str)
    end
  end
end

-- Call this after you are done defining your actors.
---@param ctx Context
function M.ready(ctx)
  oat.actor = actorInit
  ctx:lock()
  stack:clear()
  local tree = ctx:toTree()
  prettyPrintTree(tree)
  pushNewLayer(tree)
  forcedEvaluation = false
end

-- For repeat initializations to persist state across Lua state resets.
-- Will function without `Condition` and pretend those are set correctly.
---@param frame ActorFrame
function M.forceEvaluate(frame)
  print('BEGIN FORCED EVALUATION')
  for i, child in ipairs(frame:GetChildren()) do
    local cond = actorInit.Condition((i - 1) % 2 ~= 0)
    if child.GetChildren then
      M.forceEvaluate(child)
    end
    if cond then
      actorInit.Init(math.ceil(i / 2))(child)
    end
  end
end

-- Call this once all of the actors have been initialized
function M.finalize()
  stack:clear()
  oat.actor = nil
end


return M