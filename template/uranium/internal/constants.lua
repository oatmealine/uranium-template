-- indexing things on _G is slower than
-- having access to them in a local `oat` table
-- that already acts as _G, so we move commonly
-- use values over

local function copy(src)
  local dest = {}
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

oat = _G.oat
type = _G.type
print = _G.print
pairs = _G.pairs
ipairs = _G.ipairs
unpack = _G.unpack
tonumber = _G.tonumber
tostring = _G.tostring
math = copy(_G.math)
table = copy(_G.table)
string = copy(_G.string)

-- convinience shortcuts employed by most templates

scx = SCREEN_CENTER_X
scy = SCREEN_CENTER_Y
sw = SCREEN_WIDTH
sh = SCREEN_HEIGHT
dw = DISPLAY:GetDisplayWidth()
dh = DISPLAY:GetDisplayHeight()