local aftSetup = require('stdlib.aft')
require('stdlib.color')
require('stdlib.vector2D')

local coverQuad = Quad()
coverQuad:diffuse(0, 0, 0, 1)
coverQuad:xywh(scx, scy, sw, sh)

local testQuad = Quad()
testQuad:zoom(50)

local aft = ActorFrameTexture()

local aftSprite = Sprite()
aftSetup.sprite(aftSprite)
aftSprite:diffusealpha(0.99)
aftSprite:zoom(1.01)
aftSprite:rotationz(0.2)

aft:addcommand('Init', function(self)
  aftSetup.aft(aft) -- put this here; else it'll recreate it every frame!
  aftSprite:SetTexture(self:GetTexture())
end)

local text = BitmapText('common', 'uranium template!')
text:xy(scx, scy)

function uranium.update(dt)
  coverQuad:Draw()

  aftSprite:Draw()

  local rainbow = shsv(t * 1.2, 0.5, 1)

  testQuad:xy((vectorFromAngle(t * 160, 100) + vector(scx, scy)):unpack())
  testQuad:diffuse(rainbow:unpack())
  testQuad:zoom(50 * math.random())
  testQuad:Draw()

  aft:Draw()

  text:Draw()
end