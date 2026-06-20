local Proxy = require 'uranium.actors.proxy'
local events = require 'uranium.events'

local players = {}
local maxPn = 8

for pn = 1, maxPn do
  if GAMESTATE:IsPlayerEnabled((pn - 1) % 2) then
    players[pn] = Proxy.new('Player')
  end
end

events:on('ready', function()
  for pn in pairs(players) do
    Proxy.resolve(players[pn], SCREENMAN('PlayerP' .. pn))
  end
end)

return players