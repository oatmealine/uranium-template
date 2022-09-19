---@meta

-- cleaning up some notitg typing jank... ehe
---@alias int number
---@alias float number
---@alias Quad Actor
---@alias void nil

---@return Quad
--- Defines a Quad actor.
function Quad() end
---@return ActorProxy
--- Defines an ActorProxy actor.
function ActorProxy() end
---@return Polygon
--- Defines a Polygon actor.
function Polygon() end
---@param file string
---@return Sprite
--- Defines a Sprite actor.
function Sprite(file) end
---@param file string
---@return Model
--- Defines a Model actor.
function Model(file) end
---@param font string?
---@param text string?
---@return BitmapText
--- Defines a BitmapText actor.
function BitmapText(font, text) end
---@param file string
---@return ActorSound
--- Defines an ActorSound actor.
function ActorSound(file) end

---@param actor Actor
--- Resets an actor to its initial state
function reset(actor) end

---@type number
--- A simple timer. Ticks upwards at a rate of 1/sec.
---
--- **The start time is undefined!** This uses `os.clock()`, meaning this will be inconsistent between modfile starts.
---
--- It's recommended to only use this for eg. `math.sin`, rotations, and other similar visual effects. If you want a proper timer, see `b`.
t = 0

---@type number
--- The amount of beats that have passed since the start of the file.
b = 0

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

--- The Uranium Template table! Mostly callback-related stuff goes here.
uranium = {}

--- A callback for initialization. Called on `OnCommand`.
uranium.init = function() end
--- A callback for updates. Called every frame. Draw stuff here!
uranium.update = function() end

---@param event string
---@param ... any
---@return any
--- Call a defined callback.
function uranium:call(event, ...) end

--- Equivalent to a modfile-sandboxed `_G`, similar to Mirin's `xero`. You shouldn't need this; and if you do, *what are you doing?*
---@type table<any, any>
oat = {}