<center>
  <h2 style="font-size: 42px">
    <img src="docs/uranium.png" height="42px" alt="">
    <b>Uranium Template</b>
  </h2>
  <em>This place is not a place of honor... no highly esteemed deed is commemorated here... nothing valued is here.</em>
  <br>
</center>
<br>

### Please see [MANUAL.md](MANUAL.md) for the manual, and [uranium-core](https://git.oat.zone/oat/uranium-core) for the template code itself!

<br>

**Uranium Template** is a Love2D-inspired NotITG game development template, focusing on keeping things as **Lua-pure** as possible with enough abstractions to make you feel like you're not dealing with Stepmania jank at all.

Uranium Template originally formed during the creation of a currently unreleased project, and since then I've went ahead and refined and polished it up to be usable on its own. Most of the design decisions came from experience using prototype versions of it!

Uranium Template lets you define actors with a single simple function indicating their type:

```lua
local quad = Quad()
quad:xy(scx, scy)
quad:zoom(60)
```

Then define callbacks with a simple function definition:

```lua
local timer = 0
uranium.on('update', function(dt)
  timer = timer + dt
end)
```

And then define the draw order of your actors with simple method calls, similar to DrawFunctions:

```lua
uranium.on('update', function()
  quad:rotationz(t * 50)
  quad:Draw()
end)
```

It comes with an extensive standard library, including common game-development needs like:

- An [input library](MANUAL.md#input) for detecting every input supported by the game
- A simple, to-the-point [2D vector library](MANUAL.md#vector2d) that handles anything you can throw at it, including operators
- A [color library](MANUAL.md#color) that handles most formats you'll think of
- An efficient, compact non-centralized [save data library](MANUAL.md#savedata) that uses profiles for users' savefiles
- A built-in profiler for callbacks
- A [utility library](MANUAL.md#util) filled to the brim (but not bloated!) with common Lua gamedev snippets, like detecting if a table has an element, clamping, lerping and more

It supports most of what NotITG modding has to offer:

- [AFT support](MANUAL.md#actorframetexture), better than you've ever had it in XMLs
- Both inline and file [shader support](MANUAL.md#shaders)
- [Full ActorFrame support](MANUAL.md#actorframe), with nested ActorFrames all in a simple interface
- Seamless Mirin Template integration through a [built-in module](MANUAL.md#mirin)

And it has many features you've come to expect from your favorite templates:

- [Lua module loading](MANUAL.md#requiring-files) through a `require` very similar to one present in vanilla Lua
- Completely sandboxed globals
- Clear error reporting at every possible opportunity, hopefully not letting you see a single error arise from an XML file

Oh, and did I mention there's an [uwuification library](MANUAL.md#uwuify)?

And if you're still not convinced, here's a couple of testimonials from our dear users:

- "this template really adds some spice to your modfiles. think industrial glitter in your next chilli!" _- Mayflower_
- "a good template that i have definitely used! jill can i go now. jill please i just want to see my family" _- Aura_

<br/>

To get started, consult the [manual](MANUAL.md), which comes free with your template. It has everything you need to start writing code, including extensive examples and documentation for just about every function and value in the template.