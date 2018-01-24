--[[
--This script will enable an entity to stand on tiles and
--handle height maps
--
--TO USE:
--Make sure type.C.WIDTH and HEIGHT are set before calling Init
--Can specify all properties of
--class.tile.down / left / right / up
--
--	callback (packet, newPosition)- Function called after new correct position is processed
--	Handle (packet)- Function used to process a collision, shouldn't be set, can be referenced
--	shape - if the default shape isn't cutting it, then one can be set before calling Init
--	order- order processed
--
--]]
local utility = require("Utility/commonFunctions.lua")
local container = {}
container.New = function(base)
	local class = base or {}
	class.C = class.C or {}

	class.tile			= class.tile or {}
	class.tile.down		= class.tile.down or {}
	class.tile.left		= class.tile.left or {}
	class.tile.right	= class.tile.right or {}
	class.tile.up		= class.tile.up or {}

	class.tile.down.defaultOrder		= 5
	class.tile.up.defaultOrder		= 10
	class.tile.left.defaultOrder		= 15
	class.tile.right.defaultOrder	= 15

	class.tile.groundTouch	= false
	class.tile.upTouch		= false
	class.tile.leftTouch	= false
	class.tile.rightTouch	= false

	--previous frame information
	class.tile.previous = class.tile.previous or {}
	class.tile.previous.groundTouch = false
	class.tile.previous.upTouch = false
	class.tile.previous.leftTouch = false
	class.tile.previous.rightTouch = false

	local function GetHeightMapValueHorizontal(wx, hmap)
		--Get range between 0 and 15
		local index = wx % 16

		return hmap:GetHeightH(index)
	end

	local function TC_Down(packet, hmapValue)
		local td = class.tile.down

		-- Get New World Posiiton ------------
		local ty = packet:GetTileY()
		local newY = ((ty+1)*16) - hmapValue - class.C.HEIGHT

		local thisAngle=packet:GetHMap().angleH
		thisAngle= math.abs(utility.AngleToSignedAngle(thisAngle))
		if td.highestHeight ~= nil then
			if td.highestHeight < newY then
				return
			elseif td.highestHeight == newY then
				--if heights are the same, stand on the shallowest angle
				if thisAngle >= class.tile.down.shallowestAngle then
					return
				end
			end
		end

		td.shallowestAngle = thisAngle
		td.highestHeight = newY

		-- Set Position ----------------------
		local newPosition = CPP.Vec2(0,newY)
		newPosition= class.CompPos:TranslateWorldToLocal(newPosition)

		class.tile.groundTouch = true

		-- Set Callback if one exists---------
		if td.callback ~= nil then
			td.callback(packet, newPosition)
		end
	end

	function class.tile.down.HandleLeft(packet)
		local wx = class.CompPos:GetPositionWorld().x
		wx = wx + class.tile.down.shapeLeft.x
		local hmap = GetHeightMapValueHorizontal(wx, packet:GetHMap())

		TC_Down(packet, hmap)
	end

	function class.tile.down.HandleRight(packet)
		local wx = class.CompPos:GetPositionWorld().x
		wx = wx + class.tile.down.shapeRight.x
		local hmap = GetHeightMapValueHorizontal(wx, packet:GetHMap())

		TC_Down(packet, hmap)
	end

	function class.tile.left.Handle(packet)
		if usesHMaps then return end
		local tl = class.tile.left
		--left side of tile to the right of the one colided with
		local wx = (packet:GetTileX() * 16) + 16 
		local newPosition = CPP.Vec2(wx,0)
		if tl.callback ~= nil then
			tl.callback(packet, newPosition)
		end
		class.tile.leftTouch = true
	end
	function class.tile.right.Handle(packet)
		if usesHMaps then return end
		local tr = class.tile.right
		local wx = (packet:GetTileX() * 16 ) - class.C.WIDTH  
		local newPosition = CPP.Vec2(wx,0)
		if tr.callback ~= nil then
			tr.callback(packet, newPosition)
		end
		class.tile.rightTouch = true
	end
	function class.tile.up.Handle(packet)
		if usesHMaps then return end
		local tu = class.tile.up
		local wy = (packet:GetTileY() + 1) * 16
		local newPosition = CPP.Vec2(0,wy)
		if tu.callback ~= nil then
			tu.callback(packet, newPosition)
		end
		class.tile.upTouch = true
	end

	function class.tile.down.Init(CompCol)
		local c = CPP.interface
		local down = class.tile.down
		local boxLeft = math.floor(class.C.WIDTH / 4)
		local boxRight = class.C.WIDTH - boxLeft
		local shape1 = CPP.Rect(boxLeft, class.C.HEIGHT, 1, 2)
		local shape2 = CPP.Rect(boxRight, class.C.HEIGHT, 1, 2)
		down.shapeLeft = down.shape or shape1
		down.shapeRight = down.shape or shape2
		down.callback = down.callback or nil

		down.cboxLeft = CompCol:AddCollisionBox(down.shapeLeft)
		down.cboxRight = CompCol:AddCollisionBox(down.shapeRight)

		down.cboxLeft:CheckForTiles()
		down.cboxRight:CheckForTiles()
		class.tile.CheckForSolidLayers(down.cboxLeft, down.HandleLeft)
		class.tile.CheckForSolidLayers(down.cboxRight, down.HandleRight)
		down.cboxRight:SetOrder(down.order or down.defaultOrder)
		down.cboxLeft:SetOrder(down.order or down.defaultOrder)

		down.highestHeight = 0
		down.shallowestAngle = 0
	end

	function class.tile.left.Init(CompCol)
		local c = CPP.interface
		local height = class.C.HEIGHT
		local quarterHeight = math.floor(height / 4)
		-- -1 is just outside where you shouldn't collide with
		local shape = CPP.Rect(-1, quarterHeight, 0, height - (quarterHeight*2))
		local left = class.tile.left
		left.shape = left.shape or shape
		left.callback = left.callback or nil

		left.cbox= CompCol:AddCollisionBox(left.shape)
		left.cbox:CheckForTiles()
		class.tile.CheckForSolidLayers(left.cbox, left.Handle)
		left.cbox:SetOrder(left.order or left.defaultOrder)
	end

	function class.tile.right.Init(CompCol)
		local c = CPP.interface
		local height = class.C.HEIGHT
		local quarterHeight = math.floor(height / 4)
		-- class.C.Width is just outside the area you shouldn't colide with (remember '0' is a pixel)
		local shape = CPP.Rect(class.C.WIDTH, quarterHeight, 0, height - (quarterHeight*2))
		local right = class.tile.right
		right.shape = right.shape or shape
		right.callback = right.callback or nil

		right.cbox= CompCol:AddCollisionBox(right.shape)
		right.cbox:CheckForTiles()
		class.tile.CheckForSolidLayers(right.cbox, right.Handle)
		right.cbox:SetOrder(right.order or right.defaultOrder)
	end
	function class.tile.up.Init(CompCol)
		local c = CPP.interface
		local offset = math.floor(class.C.WIDTH / 4)
		local shape = CPP.Rect(offset, 0, class.C.WIDTH - (offset*2), 1)
		local up = class.tile.up
		up.shape = up.shape or shape
		up.callback = up.callback or nil

		up.cbox= CompCol:AddCollisionBox(up.shape)
		up.cbox:CheckForTiles()
		class.tile.CheckForSolidLayers(up.cbox, up.Handle)
		up.cbox:SetOrder(up.order or up.defaultOrder)
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

		local map = c:GetMap()
		class.tile.solidLayers = c:GetLayersWithProperty(map, "_SOLID", true)
		class.tile.down.Init(CompCol)
		class.tile.left.Init(CompCol)
		class.tile.right.Init(CompCol)
		class.tile.up.Init(CompCol)
	end

	function class.tile.CheckForSolidLayers(box, callback)
		for k, v in pairs(class.tile.solidLayers)do
			box:CheckForLayer(v, callback)
		end
	end

	function class.tile.Update()
		local ct = class.tile
		ct.down.highestHeight = nil
		--greater than 360 degrees
		ct.down.shallowestAngle = 400
		ct.previous.groundTouch = ct.groundTouch
		ct.groundTouch = false

		ct.previous.groundTouch = ct.groundTouch
		ct.previous.upTouch = ct.upTouch
		ct.previous.leftTouch = ct.leftTouch
		ct.previous.rightTouch = ct.rightTouch

		ct.groundTouch = false
		ct.upTouch = false
		ct.leftTouch = false
		ct.rightTouch = false
	end

	function class.tile.Deactivate()
		local t = class.tile
		t.down.cboxLeft:Deactivate()
		t.down.cboxRight:Deactivate()
		t.left.cbox:Deactivate()
		t.right.cbox:Deactivate()
		t.up.cbox:Deactivate()
	end
	function class.tile.Activate()
		local t = class.tile
		t.down.cboxLeft:Activate()
		t.down.cboxRight:Activate()
		t.left.cbox:Activate()
		t.right.cbox:Activate()
		t.up.cbox:Activate()
	end

	table.insert(class.InitFunctions, Init)

	return class
end

return container.New
