<center>
  <h2 style="font-size: 42px">
    <img src="docs/uranium.png" height="42px" alt="">
    <b>Uranium Template</b>
  </h2>
  <em>This place is not a place of honor... no highly esteemed deed is commemorated here... nothing valued is here.</em>
  <br>
</center>
<br>

**Uranium Template** is a low-level generic template for NotITG v4.9+. In
particular, it's specialized towards non-modfile development, including
minigames, file selectors, and other meta projects.

The design is pretty closely based off of the design of code-only engines like
Love2D, and the goal is to provide a solid base to develop anything with a
similar philosophy on top.

Uranium Template originally formed during the creation of a currently unreleased
project, and v2 formed during the creation of the [Mod Jam Kusoge lobby](https://www.youtube.com/watch?v=CSJ_pimhrYA).
Since then I've refined and polished it up to be usable on its own. Most of the
design decisions came from experience using prototype versions of it!

## about

Uranium Template differentiates itself from starting from scratch with
`BGCHANGES` in the following ways:

- Uranium includes a `require`/`package` implementation similar to a regular Lua
environment, which allows for much easier splitting of code into modules; all
globals made in the template are sandboxed.
- Uranium comes with `actor235`, a powerful actorgen library that creates actors
from Lua code. This is highly useful in draw function-based development where
your scene is defined in code:

  ```lua
  local uranium = require 'uranium'
  local ctx = uranium.ctx

  local quad = ctx:Quad()
  local sprite = ctx:Sprite('my/awesome/sprite.png')
  ```
- Uranium also comes with a set of other libraries useful for development under
the `stdlib` namespace, such as libraries handling input, scheduling, savedata,
events, and other miscellaneous utilities.

  ```lua
  local events = require 'uranium.events'

  local t = 0
  events:on('update', function(dt)
    t = t + dt
  end)
  ```

  ```lua
  local input = require 'stdlib.input'

  input.events:on('press', function(key, pn)
    if key == input.inputType.Start then
      print('Hi')
    end
  end)
  ```

Uranium is also different from other templates in that it is much lower level
than most other templates, which means other templates can be put into it. For
instance, as Mirin Template is a very popular choice for modfiles, the entirety
of it is actually bundled as a module in the `stdlib` namespace.

## documentation

All documentation about the download, installation, use and standard library
modules is kept in the [manual](./MANUAL.md). It has everything you need to
start writing code, including extensive examples.