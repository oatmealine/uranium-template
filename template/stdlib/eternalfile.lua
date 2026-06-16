local events = require 'uranium.events'
require 'stdlib.players'

return function()
  if P1 then
    P1:SetNoteDataFromLua({})
  end
  if P2 then
    P2:SetNoteDataFromLua({})
  end

  events:on('update', function()
    local b = GAMESTATE:GetSongBeat()
    if b >= 1 then
      GAMESTATE:SetSongBeat(b % 1)
    end
  end)
end