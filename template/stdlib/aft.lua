-- TODO: make this not suck (use contexts pleaseeee)

local uranium = require 'uranium'
local events = require 'uranium.events'

local self = {}

function self.sprite(self)
  self:basezoomx(sw / dw)
  self:basezoomy(-sh / dh)
  self:x(scx)
  self:y(scy)
end

function self.aft(self)
  self:SetWidth(dw)
  self:SetHeight(dh)
  self:EnableDepthBuffer(false)
  self:EnableAlphaBuffer(false)
  self:EnableFloat(false)
  self:EnablePreserveTexture(true)
  self:Create()
end

function self.aftSetup()
	local a = uranium.ctx:ActorFrameTexture()
	local b = uranium.ctx:Sprite()
  events:on('init', function()
    self.aft(a)
		self.sprite(b)
		b:SetTexture(a:GetTexture())
  end)
	return a, b
end

return self