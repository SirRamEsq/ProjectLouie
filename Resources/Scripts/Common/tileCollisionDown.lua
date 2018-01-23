--[[
--This script will enable an entity to stand on tiles and
--handle height maps
--
--TO USE:
--Make sure type.C.WIDTH and HEIGHT are set before calling Init
--Can specify all properties of
--class.tile.down
--
--]]

local container = {}
container.New = function(base)
	local class = base or {}
	class.C = class.C or {}
	local utility = require("Utility/commonFunctions.lua")

	class.tile = class.tile or {}
	class.tile.down = class.tile.down or {}

	local function GetHeightMapValueHorizontal(wx, hmap)
		--Get range between 0 and 15
		local index = wx % 16

		return hmap:GetHeightH(index)
	end

	local function TileCollision(packet, hmapValue)
		local td = class.tile.down

		-- Get New World Posiiton ------------
		local ty = packet:GetTileY() * 16
		local newY = ty - hmapValue

		if td.highestHight ~= nil then
			if td.highestHight <= newY then
				return
			end
		end

		td.highestHight = newY

		-- Set Position ----------------------
		local newPosition = CPP.Vec2(0,newY)
		newPosition= class.CompPos:TranslateWorldToLocal(newPosition)
		class.CompPos:SetPositionWorldY(newPosition.y)

		-- Set Callback if one exists---------
		if td.callback ~= nil then
			td.callback(packet)
		end
	end

	local function TileCollisionLeft(packet)
		local wx = class.CompPos:GetPositionWorld().x
		wx = wx + class.tile.down.shapeLeft.x
		local hmap = GetHeightMapValueHorizontal(wx, packet:GetHMap())

		TileCollision(packet, hmap)
	end

	local function TileCollisionRight(packet)
		local wx = class.CompPos:GetPositionWorld().x
		wx = wx + class.tile.down.shapeRight.x
		local hmap = GetHeightMapValueHorizontal(wx, packet:GetHMap())

		TileCollision(packet, hmap)
	end

	local function Init()
		local c = CPP.interface
		local EID = class.LEngineData.entityID
		local CompCol = c:GetCollisionComponent(EID)
		class.CompPos = c:GetPositionComponent(EID)

		class.eid = EID
		if class.C.WIDTH == nil then
			c:LogError(EID, "C.WIDTH not specfied!")
			return
		end

		local boxLeft = math.floor(class.C.WIDTH / 4)
		local boxRight = class.C.WIDTH - boxLeft
		local shape1 = CPP.Rect(boxLeft, class.C.HEIGHT, 1, 2)
		local shape2 = CPP.Rect(boxRight, class.C.HEIGHT, 1, 2)
		class.tile.down.shapeLeft = class.tile.down.shape or shape1
		class.tile.down.shapeRight = class.tile.down.shape or shape2
		class.tile.down.callback = class.tile.down.callback or nil

		class.tile.down.cboxLeft = CompCol:AddCollisionBox(class.tile.down.shapeLeft)
		class.tile.down.cboxRight = CompCol:AddCollisionBox(class.tile.down.shapeRight)

		class.tile.down.cboxLeft:CheckForTiles()
		class.tile.down.cboxRight:CheckForTiles()

		local map = c:GetMap()
		local solidLayers = c:GetLayersWithProperty(map, "_SOLID", true)
		for k, v in pairs(solidLayers)do
			class.tile.down.cboxRight:CheckForLayer(v, TileCollisionLeft)
			class.tile.down.cboxLeft:CheckForLayer(v, TileCollisionRight)
		end
		class.tile.down.highestHight = 0
	end

	local function Update()
		class.tile.down.highestHight = nil
	end

	table.insert(class.InitFunctions, Init)
	table.insert(class.UpdateFunctions, Update)

	return class
end

return container.New
