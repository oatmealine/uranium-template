local self = {}

-- Sets up a Sprite for textures from AFTs, scaling it with the display
-- resolution
---@param sprite Sprite
function self.setupSprite(sprite)
  sprite:basezoomx(sw / dw)
  sprite:basezoomy(-sh / dh)
  sprite:x(scx)
  sprite:y(scy)
end

-- Creates a Sprite for textures from AFTs, scaling it with the display
-- resolution
--
-- Like `setupSprite`, but includes creating the Sprite from a Context
---@param ctx Context
function self.createSprite(ctx)
  local sprite = ctx:Sprite()
  self.setupSprite(sprite)
  return sprite
end

-- Sets up an AFT that will capture the entire scene when drawn
---@param aft ActorFrameTexture
function self.setupAFT(aft)
  aft:SetWidth(dw)
  aft:SetHeight(dh)
  aft:EnableDepthBuffer(false)
  aft:EnableAlphaBuffer(false)
  aft:EnableFloat(false)
  aft:EnablePreserveTexture(true)
  aft:Create()
end

-- Creates an AFT that will capture the entire scene when drawn
--
-- Like `setupAFT`, but includes creating the AFT from a Context
---@param ctx Context
function self.createAFT(ctx)
  local aft = ctx:ActorFrameTexture()
  self.setupAFT(aft)
  return aft
end

-- Creates a sprite with `createSprite`, an AFT with `createAFT`, and assigns
-- the sprite a texture from the AFT, returning both
---@param ctx Context
---@return ActorFrameTexture, Sprite
function self.createEffectStack(ctx)
	local aft = self.createAFT(ctx)
  local sprite = self.createSprite(ctx)
  sprite:addcommand('Init', function()
		sprite:SetTexture(aft:GetTexture())
  end)
	return aft, sprite
end

return self