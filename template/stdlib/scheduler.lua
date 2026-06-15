local self = {}

local events = require 'uranium.events'

local scheduled = {
}
local scheduledTicks = {
}

local function getHighestKey(t)
  local s = 0
  for k in pairs(t) do
    s = math.max(s, k)
  end
  return s
end

function self:schedule(when, func)
  local index = getHighestKey(scheduled) + 1
  scheduled[index] = {when, func}
  return index
end

function self:scheduleInTicks(when, func)
  local index = getHighestKey(scheduledTicks) + 1
  scheduledTicks[index] = {when, func}
  return index
end

function self:unschedule(i)
  if not i then
    print('warning: trying to unschedule a non-existent event')
    return
  end
  scheduled[i] = nil
end

function self:unscheduleInTicks(i)
  if not i then
    print('warning: trying to unschedule a non-existent event')
  end
  scheduledTicks[i] = nil
end

events:on('update', function(dt)
  for k, s in pairs(scheduledTicks) do
    s[1] = s[1] - 1
    if s[1] <= 0 then
      s[2]()
      scheduledTicks[k] = nil
    end
  end

  for k, s in pairs(scheduled) do
    s[1] = s[1] - dt
    if s[1] <= 0 then
      s[2]()
      scheduled[k] = nil
    end
  end
end)

return self