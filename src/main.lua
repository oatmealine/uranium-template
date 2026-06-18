local uranium = require 'uranium'
local events = require 'uranium.events'
local players = require 'stdlib.players'

players[1]:hidden(1)
players[2]:hidden(1)

require 'stdlib.eternalfile'

local ctx = uranium.ctx

-- define a basic quad
local quad = ctx:Quad()
quad:xy(scx, scy)

-- define a sprite
local sprite = ctx:Sprite('docs/uranium.png')
sprite:xy(scx, scy)

-- let's add some text aswell
local text = ctx:BitmapText('common', 'hello, uranium template v' .. uranium.release.version .. '!')
text:xy(scx, scy + 100)

-- update gets called every frame
-- dt here refers to deltatime - the time that has passed since the last frame!
local t = 0
events:on('update', function(dt)
  t = t + dt

  -- let's set some properties on the quad
  quad:zoom(120)
  quad:diffuse(0.8, 1, 0.7, 1)
  quad:skewx(0.2)
  quad:rotationz(t * 80)
  -- then shove it to the screen - similar to a drawfunction!
  quad:Draw()
  -- and you can do this multiple times of course!
  quad:zoomto(180, 180)
  quad:rotationz(t * 100)
  quad:diffusealpha(0.4)
  quad:skewx(0.1)
  quad:Draw()

  -- throw in the logo aswell, because why not
  -- zoom and glow is done for a quick-and-dirty outline
  sprite:zoom(sprite:GetZoom() * 1.1)
  sprite:glow(1, 1, 1, 1)
  sprite:Draw()

  sprite:zoom(0.4)
  sprite:glow(1, 1, 1, 0)
  sprite:Draw()

  -- for the text, get a (quick and dirty) rainbow color
  local r, g, b =
    0.75 + 0.25 * math.cos(t),
    0.75 + 0.25 * math.cos(t - 2/3 * math.pi),
    0.75 + 0.25 * math.cos(t - 4/3 * math.pi)
  text:diffuse(r, g, b, 1)
  -- wag the text
  text:rotationz(math.sin(t * 2) * 10)
  text:Draw()
end)
