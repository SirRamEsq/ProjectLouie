local container = {}
container.New = function(baseclass)
	local MOVE_SPEED = 1

	class = baseclass or {}
	class.C = class.C or {}
	class.C.WIDTH = 16
	class.C.HEIGHT = 16
	class.input = require("Utility/input.lua")
	class.xspd = 0
	class.yspd = 0

	local Init = function()
		class.EID	= class.LEngineData.entityID
		class.name = class.LEngineData.name

		local EID = class.EID
		class.CompCollision = CPP.interface:GetCollisionComponent(EID)
		class.CompSprite	= CPP.interface:GetSpriteComponent(EID)
		class.CompPosition  = CPP.interface:GetPositionComponent(EID)
		class.depth	= class.CompSprite:GetDepth()

		--Input
		class.c = class.c or {}
		class.c.K_UP = "up"
		class.c.K_DOWN = "down"
		class.c.K_LEFT = "left"
		class.c.K_RIGHT = "right"
		class.c.K_ACTIVATE = "activate"
		CPP.interface:ListenForInput(EID, class.c.K_UP)
		CPP.interface:ListenForInput(EID, class.c.K_DOWN)
		CPP.interface:ListenForInput(EID, class.c.K_LEFT)
		CPP.interface:ListenForInput(EID, class.c.K_RIGHT)
		CPP.interface:ListenForInput(EID, class.c.K_ACTIVATE)
		class.input.RegisterKey( class.c.K_UP   )
		class.input.RegisterKey( class.c.K_DOWN )
		class.input.RegisterKey( class.c.K_LEFT )
		class.input.RegisterKey( class.c.K_RIGHT)
		class.input.RegisterKey( class.c.K_ACTIVATE)

		--Sprite
		class.spriteRSC	 = CPP.interface:LoadSpriteResource("worldMapLouie.xml")
		class.sprite = class.CompSprite:AddSprite(class.spriteRSC)
	end

	function class.OnKeyDown(keyname)
		class.input.OnKeyDown(keyname)
	end

	function class.OnKeyUp(keyname)
		class.input.OnKeyUp(keyname)
	end

	local Update = function()
		class.HandleInput()
		class.Animate()
		local updateVec = CPP.Vec2(class.xspd, class.yspd)
		class.CompPosition:SetMovement(updateVec)
	end

	function class.Animate()
		if (class.xspd == 0) and (class.yspd == 0)then
			class.sprite:SetAnimation("Stand")
		else
			class.sprite:SetAnimation("Walk")
			class.sprite:SetAnimationSpeed(.1)
			if(class.xspd > 0)then
				class.sprite:SetScalingX(1)
			elseif(class.xspd < 0)then
				class.sprite:SetScalingX(-1)
			end
		end

	end

	function class.HandleInput()
		--Up/down Held
		if (class.input.key[class.c.K_UP]) then
			class.yspd = -MOVE_SPEED
		elseif (class.input.key[class.c.K_DOWN]) then
			class.yspd = MOVE_SPEED
		else
			class.yspd = 0
		end

		-- left/right Held
		if (class.input.key[class.c.K_LEFT]) then
			class.xspd = -MOVE_SPEED
		elseif (class.input.key[class.c.K_RIGHT]) then
			class.xspd = MOVE_SPEED
		else
			class.xspd = 0
		end
	end

	table.insert(class.InitFunctions, Init)
	table.insert(class.UpdateFunctions, Update)

	class.EntityInterface = class.EntityInterface or {}
	local ei = class.EntityInterface
	ei.IsPlayer	= function ()		return true end

	return class
end

return container.New
