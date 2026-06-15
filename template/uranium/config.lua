-- Uranium's configuration system, providing methods to configure parts
-- of the template.
---@class UraniumConfig
local M = {}

-- Toggle if theme actors (lifebars, scores, song names, etc.) are hidden. Must be toggled **before** `init`.
M.hideThemeActors = true

return M