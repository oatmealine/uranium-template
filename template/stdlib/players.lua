local Proxy = require 'uranium.actors.proxy'
local events = require 'uranium.events'

local MAX_PN = 8
-- NOTE: players 2, 4, 6, 8 will be missing in singleplayer
---@type { [1]: Player, [2]: Player, [3]: Player, [4]: Player, [5]: Player, [6]: Player, [7]: Player, [8]: Player }
local players = {}

for pn = 1, MAX_PN do
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
