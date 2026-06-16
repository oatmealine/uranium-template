-- A proxy stand-in for an actor, used until the real actor is available.
-- 
-- Calls to this actor will be "queued", being held in memory until the proxy is
-- resolved, after which they'll all be ran in order.
-- Calls to `addcommand` with `Init` are overridden and also called after the
-- proxy is resolved.
--
-- Values from queued function calls are not returned. Other than that caveat, a
-- proxy of an actor will behave the same as regular calls to the actor, albeit
-- delayed.
local Proxy = {}

-- These functions override the actual Actor methods.
local actorMethodOverrides = {}

-- Calls a method on a resolved proxy
function Proxy.call(proxy, key, _, ...)
  if not Proxy.resolved(proxy) then
    error('actor235: attempting to call method on unresolved proxy', 2)
  end
  local actor = proxy.__proxy.raw
  -- normally you'd be concerned with return values here, but there's not really
  -- anything to return here _to_
  local res, err = pcall(actor[key], actor, unpack(arg))
  if not res then
    error('error calling ' .. key .. ': ' .. err, 2)
  end
end

local methodCache = setmetatable({}, {__mode = 'v'})

-- Wraps a method, letting it be called as if it was on the real actor.
--
-- When a method on an object in Lua is called with :, then the object is passed
-- in as the first argument. This is inconvenient for proxies, since that object
-- will be the proxy instead of the actor, potentially causing an AV.
--
-- This function will wrap the call, resolving the proxy first, and then
-- proceeding with the call as usual.
function Proxy.wrapCall(func)
  if methodCache[func] then return methodCache[func] end

  -- defining ahead-of-time to avoid creating an anonymous function each time

  local protected = function(args)
    -- wrapping it in a table because in a pcall lua will only pass along the
    -- first returned value
    return {func(unpack(args))}
  end

  local wrapped = function(...)
    arg[1] = Proxy.getRaw(arg[1])
    local ok, res = pcall(protected, arg)
    if not ok then error(res, 2) end
    return unpack(res)
  end

  methodCache[func] = wrapped

  return wrapped
end

-- Resolves a proxy, realizing its actor and making it run through the backlog
-- of called methods
function Proxy.resolve(proxy, actor)
  if Proxy.resolved(proxy) then
    error('actor235: proxy has already been resolved', 2)
  end
  proxy.__proxy.raw = actor

  -- work through the queue

  for _, v in ipairs(proxy.__proxy.methodQueue) do
    local func = actor[v.key]
    if not func then
      error(
        'actor235: error while initializing \'' .. proxy.__proxy.name .. '\' on ' .. v.debug.short_src .. ':' .. v.debug.currentline .. ':\n' ..
        'you\'re calling a function \'' .. v.key .. '\' on a ' .. proxy.__proxy.name .. ' which doesn\'t exist!:\n'
      )
    else
      local success, result = pcall(function()
        Proxy.call(proxy, v.key, unpack(v.arg))
      end)
      if not success then
        error(
          'actor235: error while initializing \'' .. proxy.__proxy.name .. '\' on ' .. v.debug.short_src .. ':' .. v.debug.currentline .. ':\n' ..
          result
        )
      end
    end
  end

  proxy.__proxy.methodQueue = {}

  -- run the initcommands

  for _, c in ipairs(proxy.__proxy.initCommands) do
    local func = c[1]
    local success, result = pcall(function()
      func(actor)
    end)
    if not success then
      error(
        'actor235: error on \'' .. proxy.__proxy.name .. '\' InitCommand defined on ' .. c.debug.short_src .. ':' .. c.debug.currentline .. ':\n' ..
        result
      )
    end
  end

  proxy.__proxy.initCommands = {}
end

function Proxy.resolved(proxy)
  return proxy.__proxy.raw ~= nil
end

function Proxy.getRaw(proxy)
  return proxy.__proxy.raw
end

function Proxy.isProxy(proxy)
  return rawget(proxy, '__proxy') ~= nil
end

function Proxy.setData(proxy, key, value)
  assert(Proxy.isProxy(proxy), 'actor235: passed in value is not a Proxy')
  proxy.__proxy.data[key] = value
  return value
end

function Proxy.getData(proxy, key)
  assert(Proxy.isProxy(proxy), 'actor235: passed in value is not a Proxy')
  return proxy.__proxy.data[key]
end

-- Once you have the actual actor, call `Proxy.resolve`.
---@param name string
function Proxy.new(name)
  return setmetatable({
    __proxy = {
      name = name,
      raw = nil,
      initCommands = {},
      methodQueue = {},
      methodCache = {},
      -- custom user data
      data = {},
    },
  }, {
    __name = name,
    __tostring = function(self)
      return 'Proxy of ' .. (self.__proxy.raw and tostring(self.__proxy.raw) or (self.__proxy.name .. ' (unresolved)'))
    end,

    __newindex = function()
      error('actor235: cannot set properties on actors!', 2)
    end,
    __index = function(self, key)
      -- return if resolved
      if Proxy.resolved(self) then
        local actor = self.__proxy.raw

        if actorMethodOverrides[key] then
          return actorMethodOverrides[key]
        end

        local val = actor[key]
        if type(val) == 'function' then
          return Proxy.wrapCall(val)
        end
        return val
      end

      -- otherwise, queue it up
      return function(...)
        if key == 'addcommand' and arg[2] == 'Init' then
          table.insert(self.__proxy.initCommands, {
            arg[3],
            debug = debug.getinfo(2, 'Sl'),
          })
        else
          table.insert(self.__proxy.methodQueue, {
            key = key,
            arg = arg,
            debug = debug.getinfo(2, 'Sl'),
          })
        end
      end
    end,
  })
end

return Proxy