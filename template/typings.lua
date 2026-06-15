---@meta

---@type ActorFrame
--- The root ActorFrame. Use this for `addcommand` and similar!
_main = {}

---@type number
--- The center of the screen on the X axis. Equal to `SCREEN_CENTER_X`.
scx = 0
---@type number
--- The center of the screen on the Y axis. Equal to `SCREEN_CENTER_Y`.
scy = 0
---@type number
--- The screen width. Equal to `SCREEN_WIDTH`.
sw = 0
---@type number
--- The screen height. Equal to `SCREEN_HEIGHT`.
sh = 0
---@type number
--- The display width.
dw = 0
---@type number
--- The display height.
dh = 0

--- Equivalent to a modfile-sandboxed `_G`, similar to Mirin's `xero`. You shouldn't need this; and if you do, *what are you doing?*
oat = _G

--- A shorthand for `GAMESTATE:GetCurrentSong():GetSongDir()`
---@type string
package.base = ''