require('stdlib.util')

local self = {}

self.inEditor = SCREENMAN:GetTopScreen():GetName() == 'ScreenEdit'
self.onWine = includes(INPUTMAN:GetDescriptions(), 'Wine Keyboard')

return self