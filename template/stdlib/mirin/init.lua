xero = oat

local uranium = require 'uranium'
local events = require 'uranium.events'

local xeroActorsAF = uranium.ctx:ActorFrame()
xero.foreground = xeroActorsAF
xero.MIRIN_VERSION = 'URANIUM-5.0.1'


-- Load all of the core .lua files
-- The order DOES matter here:
-- std.lua needs to be loaded first
-- template.lua needs to be last
require('stdlib.mirin.std')
require('stdlib.mirin.sort')
require('stdlib.mirin.ease')
require('stdlib.mirin.template')

events:on('init', function()
  xero.init_command(xeroActorsAF)
end)