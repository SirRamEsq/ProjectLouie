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
	class.C.HEIGHT = 16
	class.C.GRAVITY = 0.21875
	class.lifeTime = 60 -- ten seconds
	class.initialSpeed = {x=1, y=0}

	class.delete = nil

	function class.FadeOutDelete()
		local alpha = 1
		class.entityCollision.Deactivate()
		return function()
			alpha = alpha - 0.025
			class.sprite:SetAlpha(alpha)
			if alpha <= 0 then
				CPP.interface.entity:Delete(class.EID)
			end
		end
	end

	local Init = function()
		local LED = class.LEngineData
		local ini = LED.InitializationTable
		local c = CPP.interface
		local EID = LED.entityID;
		class.EID = EID

		class.initialSpeed = ini.initialSpeed or class.initialSpeed
		class.lifeTime = ini.lifeTime or class.lifeTime
		class.speed = class.initialSpeed
		class.framesAlive = 0

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
		class.tile.down.callback = class.TileCollisionBottom
		class.tile.left.callback = class.TileCollisionLeft
		class.tile.right.callback = class.TileCollisionRight
	end

	local Update = function()
		class.framesAlive = class.framesAlive + 1
		class.speed.y = class.speed.y + class.C.GRAVITY
		local movement = CPP.Vec2(class.speed.x, class.speed.y)
		class.CompPos:SetMovement(movement)
		class.tile.Update()

		if class.delete ~= nil then
			class.delete()
		else
			if class.speed.x < 1 or class.framesAlive >= class.lifeTime then
				class.delete = class.FadeOutDelete()
			end
		end
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

	class.TileCollisionBottom = function(packet, newPosition)
		if class.speed.y > 0 then
			class.speed.y = 0
			class.CompPos:SetPositionWorldY(newPosition.y)
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
