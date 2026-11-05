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
local NOP_FRAG_FILENAME = 'nop.frag'
local NOP_VERT_FILENAME = 'nop.vert'

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

local function log(n)
  return math.log(n)/math.log(NODES_PER_AF)
end
if NODES_PER_AF == 10 then
	log = math.log10
end

---@class AbstractActorChild
---@field Type string?
---@field File string?
---@field Font string?
---@field Init? fun(self: Actor): nil
---@field Frag string
---@field Vert string
---@class AbstractActorFrame
---@field Type 'ActorFrame'
---@field Children AbstractActor[]
---@field Init? fun(self: Actor): nil
---@alias AbstractActor AbstractActorChild | AbstractActorFrame

---@class NodeStack
---@field actorIdx number @ The current actor's index, referring to `actors` (1-indexed)
---@field actors AbstractActor[] @ Actors that should be defined in this stack (max len NODES_PER_AF)

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

-- like print() but indented with the stack size
function stack:log(...)
  local msg = {}
  for _, val in ipairs(arg) do
    table.insert(msg, tostring(val))
  end
  print(string.rep('  ', #self) .. table.concat(msg, '\t'))
end

-- returns "what is the depth needed to hold n actors?"
---@param n number
local function getMinDepth(n)
  local depth = math.ceil(log(n))
  return math.max(depth, 1)
end

---@param actors AbstractActor[]
local function pushNewLayer(actors)
  stack:log('++')

  stack:push({
    actorIdx = 1,
    actors = actors,
  })

  --stack:log('<!-- there are ' .. #actors .. ' actors -->')
end

local currentActor

local function popStack()
  stack:pop()
  stack:log('--')
  if not stack:top() then
    M.finalize()
  else
    --print('restoring previous currentActor')
    -- restore previous currentActor for the InitCommmand immediately after
    -- an actorframe can't have shaders, so we don't need to account for
    -- Condition with hasShader making actorIdx +1 more than it should be
    local s = stack:top()
    currentActor = s.actors[s.actorIdx]
    print('set currentActor to ' .. tostring(currentActor.Type) .. ' (' .. tostring(s.actorIdx) .. '/' .. tostring(#s.actors) .. ')')
  end
end

local actorInit = {}

-- functions here are ordered in calling order

function actorInit.Condition(hasShader)
  local s = stack:top()

  currentActor = s.actors[s.actorIdx]

  if hasShader then
    s.actorIdx = s.actorIdx + 1
  end

  --stack:log('// s.actorIdx = ' .. tostring(s.actorIdx))

  if not currentActor then
    stack:log('<!-- Condition(' .. tostring(hasShader) .. ') = ' .. tostring(false) .. ' -->')
    if s.actorIdx > NODES_PER_AF and hasShader then
      print('we should go back now, since we\'re not making this actor and it\'s the last one')
      popStack()
    end
    return false
  end

  local needsShader = not not (currentActor.Frag or currentActor.Vert)
  if hasShader ~= needsShader then
    stack:log('<!-- Condition(' .. tostring(hasShader) .. ') = ' .. tostring(false) .. ' -->')
    if hasShader then
      if s.actorIdx > NODES_PER_AF and hasShader then
        print('we should go back now, since we\'ve made this actor and it\'s the last one')
        popStack()
      end
    end
    return false
  end

  stack:log('<>')

  stack:log('  Condition(' .. tostring(hasShader) .. ') = ' .. tostring(true))
  return true
end

-- none of the below functions are called if Condition returns false

function actorInit.Type()
  if currentActor.Children then
    return nil
  else
    stack:log('  Type = ' .. tostring(currentActor.Type))
    return currentActor.Type
  end
end

function actorInit.File()
  if currentActor.Children then
    stack:log('  File = ' .. ACTORS_FILENAME)
    stack:log('</><children>')
    pushNewLayer(currentActor.Children)
    return ACTORS_FILENAME
  else
    stack:log('  File = ' .. tostring(currentActor.File))
    return currentActor.File
  end
end

function actorInit.Font()
  stack:log('  Font = ' .. tostring(currentActor.Font))
  return currentActor.Font
end

function actorInit.Frag()
  stack:log('  Frag = ' .. tostring(currentActor.Frag))
  return currentActor.Frag or NOP_FRAG_FILENAME
end

function actorInit.Vert()
  stack:log('  Vert = ' .. tostring(currentActor.Vert))
  return currentActor.Vert or NOP_VERT_FILENAME
end

---@param idx number @ a number from 1 to NODES_PER_AF, inclusive
function actorInit.Init(idx)
  ---@param self Actor
  return function(self)
    stack:log('</> -> ' .. tostring(self))

    if self.GetChildren and not self.Create then
      print('lowkey i\'m an actorframe. um')
      print(currentActor)
      print(currentActor and currentActor.Type)
    end

    if currentActor then
      print('calling currentActor\'s init')
      if currentActor.Init then currentActor.Init(self) end
    end

    if idx == NODES_PER_AF and ((not currentActor) or (currentActor.Frag or currentActor.Vert)) then
      print('we should go back now, we\'ve made the last actor here and no condition statements follow')
      popStack()
    else
      currentActor = nil
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
---@field actorQueue ({ proxy: unknown, toXML: fun(): AbstractActor, subContext: Context? })[]
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

---@return AbstractActor[]
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

---@param actors AbstractActor[]
---@return AbstractActorFrame
local function wrapFrame(actors)
  return {
    Type = 'ActorFrame',
    Children = actors
  }
end

---@param actors AbstractActor[]
---@param depth number
---@param desiredDepth number
---@return AbstractActor[]
local function unstack(actors, depth, desiredDepth)
  if depth < desiredDepth then
    ---@type AbstractActorFrame[]
    local frames = {}
    for _ = 1, NODES_PER_AF do
      if #actors == 0 then break end
      table.insert(frames, wrapFrame(unstack(actors, depth + 1, desiredDepth)))
    end
    return frames
  else
    local children = {}
    for _ = 1, NODES_PER_AF do
      ---@type AbstractActorChild | AbstractActorFrame
      local actor = table.remove(actors, 1)
      if not actor then break end

      if actor.Type == 'ActorFrame' then
        local frameChildren = actor.Children
        local frameDesiredDepth = getMinDepth(#frameChildren)
        actor.Children = unstack(frameChildren, 1, frameDesiredDepth)
        table.insert(children, actor)
      else
        table.insert(children, actor)
      end
    end
    return children
  end
end

---@param tree AbstractActor[]
---@return AbstractActorFrame
local function abstractToPhysical(tree)
  local depth = getMinDepth(#tree)
  return unstack(tree, 1, depth)
end

-- Call this after you are done defining your actors.
---@param ctx Context
function M.ready(ctx)
  oat.actor = actorInit
  ctx:lock()
  stack:clear()
  local abstractTree = ctx:toTree()
  print('== ABSTRACT TREE: ==')
  print('')
  prettyPrintTree(abstractTree)
  print('')
  print('== PHYSICAL TREE: ==')
  print('')
  local physicalTree = abstractToPhysical(abstractTree)
  prettyPrintTree(physicalTree)
  print('')
  print('== OK; pushing to stack ==')
  print('')
  pushNewLayer(physicalTree)
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
  print('DONE')
  stack:clear()
  oat.actor = nil
end


return M
