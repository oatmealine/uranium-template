local Proxy = require 'uranium.actors.proxy'
local events = require 'uranium.events'

local players = {}
local maxPn = 8

for pn = 1, maxPn do
  players[pn] = Proxy.new('Player')
end

events:on('ready', function()
  for pn = 1, maxPn do
    Proxy.resolve(players[pn], SCREENMAN('PlayerP' .. pn))
  end
end)

return players