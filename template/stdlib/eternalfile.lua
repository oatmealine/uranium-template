local events = require 'uranium.events'
local players = require 'stdlib.players'

if players[1] then
  players[1]:SetNoteDataFromLua({})
end
if players[2] then
  players[2]:SetNoteDataFromLua({})
end

events:on('update', function()
  local b = GAMESTATE:GetSongBeat()
  if b >= 1 then
    GAMESTATE:SetSongBeat(b % 1)
  end
end)