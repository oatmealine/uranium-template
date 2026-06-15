-- TODO force this to only work on ready to prevent epic crashes on screengameplay

local max_pn = 8

---@type Player[]
P = {}
-- for type declarations
---@type Player
P1 = nil
---@type Player
P2 = nil
---@type Player
P3 = nil
---@type Player
P4 = nil
---@type Player
P5 = nil
---@type Player
P6 = nil
---@type Player
P7 = nil
---@type Player
P8 = nil

for pn = 1, max_pn do
  local player = SCREENMAN('PlayerP' .. pn)
  oat['P' .. pn] = player
  P[pn] = player
end