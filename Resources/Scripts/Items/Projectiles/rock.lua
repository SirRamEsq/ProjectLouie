--[[
--Expects
--initialSpeed.x
--initialSpeed.y
--]]
local container = {}
container.New = function(base)
	local utility = require("Utility/commonFunctions.lua")
	local class = base or {}
	class.C = class.C or {}
	class.C.spriteName = "rock.xml"
	class.C.animationRoll = "Roll"
	class.C.WIDTH = 16
	class.C.GRAVITY = 0.21875

	local Init = function()
		local LED = class.LEngineData
		local c = CPP.interface
		local EID = LED.entityID;
		class.EID = EID

		class.initialSpeed = LED.InitializationTable.initialSpeed --or {x=1,y=0}
		class.speed = class.initialSpeed

		class.CompSprite = c:GetSpriteComponent(EID)
		class.CompPos = c:GetPositionComponent(EID)

		---SPRITE-----------------------------------------------------
		local spriteName = class.C.spriteName
		local spriteRSC = c:LoadSpriteResource(spriteName)
		if(spriteRSC == nil)then
			c:LogError("Sprite named '" .. spriteName .. "' is NIL")
		end

		class.sprite = class.CompSprite:AddSprite(spriteRSC)
		class.sprite:SetAnimation(class.C.animationRoll)

		---Collision--------------------------------------------------
		class.CompCollision = c:GetCollisionComponent(EID)
		class.col = {}
		local shape = CPP.Rect(-8,-8,8,8)
		local box = class.CompCollision:AddCollisionBox(shape)
		box:CheckForTiles(class.TileCollisionLeft)
		class.col.boxLeft = box

		shape = CPP.Rect(24,-8,-8,8)
		box = class.CompCollision:AddCollisionBox(shape)
		box:CheckForTiles(class.TileCollisionRight)
		class.col.boxRight = box
	end

	local Update = function()
		class.speed.y = class.speed.y + class.C.GRAVITY
		local movement = CPP.Vec2(class.speed.x, class.speed.y)
		class.CompPos:SetMovement(movement)
	end

	function class.ReverseDirection()
		class.speed.x = class.speed.x * -0.8
	end

	class.TileCollisionLeft = function(packet)
		if class.speed.x < 0 then
			class.ReverseDirection()
		end
	end

	class.TileCollisionRight = function(packet)
		if class.speed.x > 0 then
			class.ReverseDirection()
		end
	end

	class.TileCollisionBottom = function(packet)
		if class.speed.y > 0 then
			local newY = packet:GetTileY() * 16
			class.speed.y = 0

			class.CompPos:SetPositionWorldY(newY)
		end
	end

	class.OnEntityCollision = function(eid, packet)
		local otherEntity = CPP.interface:EntityGetInterface(eid)
		otherEntity.Attack(1)
	end

	table.insert(class.InitFunctions, Init)
	table.insert(class.UpdateFunctions, Update)

	return class
end

return container.New
