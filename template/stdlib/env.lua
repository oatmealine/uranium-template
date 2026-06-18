local self = {}

self.inEditor = SCREENMAN:GetTopScreen():GetName() == 'ScreenEdit'
self.onWine = false
for _, keyboard in ipairs(INPUTMAN:GetDescriptions()) do
  if keyboard == 'Wine Keyboard' then
    self.onWine = true
    break
  end
end

return self