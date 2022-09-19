-- define a basic quad
local quad = Quad()
quad:xy(scx, scy)
quad:zoomto(120, 120)
quad:diffuse(0.8, 1, 0.7, 1)
quad:skewx(0.2)

-- define a sprite
local sprite = Sprite('../docs/uranium.png')
sprite:xy(scx, scy)
sprite:zoom(0.4)

-- let's add some text aswell
local text = BitmapText('common', 'hello, uranium template!')
text:xy(scx, scy + 100)

-- update gets called every frame
-- dt here refers to deltatime - the time that has passed since the last frame!
function uranium.update(dt)
  -- let's rotate our quad
  quad:rotationz(t * 80)
  -- then shove it to the screen - similar to a drawfunction!
  quad:Draw()
  -- and you can do this multiple times of course!
  quad:zoomto(180, 180)
  quad:rotationz(t * 100)
  quad:diffusealpha(0.4)
  quad:skewx(0.1)
  quad:Draw()
  -- no need to reset properties - uranium resets all properties that you set upon definition!

  -- throw in the logo aswell, because why not
  sprite:Draw()

  -- for the text, get a rainbow color
  local col = rgb(1, 0.4, 0.4):huesmooth(t * 0.6)
  text:diffuse(col:unpack()) -- the :unpack() is necessary when passing into :diffuse()
  -- wag the text
  text:rotationz(math.sin(t * 2) * 10)
  text:Draw()
end