local uranium = require 'uranium'
local rootCtx = uranium.ctx

local events = require 'uranium.events'
local actors = require 'uranium.actors'
local Context = actors.Context

local af = rootCtx:ActorFrame()
af:xy(scx, scy)
local ctx = Context.getContext(af)

local sprite = ctx:Sprite('docs/uranium.png')

local quadsAF = ctx:ActorFrame()
local quadCtx = Context.getContext(quadsAF)

local quads = {}
for i = 1, 50 do
  local q = quadCtx:Quad()
  q:zoom(math.random(30, 50))
  q:xy(math.random(-200, 200), math.random(-200, 200))
  q:diffusealpha(0.7)
  q:rotationx(math.random(0, 360))
  q:rotationy(math.random(0, 360))
  q:rotationz(math.random(0, 360))
  table.insert(quads, q)
end

local t = 0

quadsAF:SetDrawFunction(function()
  for _, v in ipairs(quads) do
    v:Draw()
  end

  quadsAF:rotationz(-t * 30)
end)

af:SetDrawFunction(function()
  quadsAF:Draw()

  af:rotationz(t * 90)
  af:zoom(1 + math.sin(t) * 0.2)

  sprite:xy(math.cos(t) * 100, math.sin(t) * 100)

  sprite:zoom(0.45)
  sprite:glow(1, 1, 1, 1)
  sprite:Draw()

  sprite:zoom(0.4)
  sprite:glow(1, 1, 1, 0)
  sprite:Draw()
end)

events:on('init', function()
  print(af, quadsAF)
end)

events:on('update', function(dt)
  t = t + dt
  af:Draw()
end)