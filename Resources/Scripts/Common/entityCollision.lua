--[[
--TO USE:
--Make sure class.C.WIDTH and HEIGHT are set before calling Init
--
--Can override the following functions before Init is called
--	class.OnEntityCollision
--]]
local container = {}

function container.new(base)
	local class = base or {}
	local result
	class.entityCollision = {}
	class.entityCollision.primary = {}
	class.entityCollision.primary.box = nil
	class.entityCollision.primary.ID = 0

	class.InitFunctions = class.InitFunctions or {}

	function printTable(t)
		local retString = ""
		for k,v in pairs(t)do
			retString = retString .. "\r\n ["..tostring(k).."] = "..tostring(v)
		end
		return retString
	end


	function tileInit()
		local eid = class.LEngineData.entityID
		local collision = CPP.interface:GetCollisionComponent(eid)

		--Primary collision
		class.entityCollision.primary.shape = CPP.Rect(0, 0, class.C.WIDTH, class.C.HEIGHT)
		local shape = class.entityCollision.primary.shape

		class.entityCollision.primary.box = collision:AddCollisionBox(shape)

		local box = class.entityCollision.primary.box
		box:CheckForEntities()
		collision:SetPrimaryCollisionBox(box)
	end

	function class.OnTileCollision(packet)
		local position = CPP.interface:GetPositionComponent(eid)
		local absolutePos = position:GetPositionWorld():Round()
		local speed = position:GetMovement():Round()
		class.tileCollision.OnTileCollision(packet, speed.x, speed.y, absolutePos.x, absolutePos.y)
	end

	function class.OnEntityCollision(entityID, packet)
		local eid = class.LEngineData.entityID
		--CPP.interface:LogWarn(eid, tostring(eid) .. " Needs to have OnEntityCollision defined")
	end

	function class.entityCollision.Deactivate()
		class.entityCollision.primary.box:Deactivate()
	end
	function class.entityCollision.Activate()
		class.entityCollision.primary.box:Activate()
	end

	--Add to sequence of init functions to call
	table.insert(class.InitFunctions, tileInit)

	return class;
end

return container.new
