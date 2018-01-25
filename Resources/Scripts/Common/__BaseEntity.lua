--Base class for ALL Entities run from LEngine

local BaseEntity = {}
local utility = require("Utility/commonFunctions.lua")

function BaseEntity.new(ignoringThis)
	--http://lua-users.org/wiki/ObjectOrientationClosureApproach
	--baseclass can be passed, but is completely ignored
	local base = {}
	--Constant variables, meant to be set once by other scripts
	base.C = {}
	-- (ENUM) different kind of attacks that can be performed
	base.C.ATTACK = {}
	base.C.ATTACK.WEAK = 1
	base.C.ATTACK.STRONG = 10
	base.C.ATTACK.SPIN = 2

	base.C.EID = 0
	base.C.WIDTH = 0
	base.C.HEIGHT = 0
	base.UpdateFunctions = {}
	base.InitFunctions = {}
	base.LuaEventFunctions = {}
	base.overrideUpdateFunction = nil

	function base.Initialize()
		base.C.EID = base.LEngineData.entityID
		for k,v in pairs(base.InitFunctions) do
			v()
		end
	end

	function base.Update()
		if base.overrideUpdateFunction ~= nil then
			base.overrideUpdateFunction()
			return
		end
		for k,v in pairs(base.UpdateFunctions) do
			v()
		end
	end

	function base.Attacked(attack)
		local EID = base.C.EID
		local c = CPP.interface
		if attack == base.C.ATTACK.SPIN then
			c:GetCollisionComponent(EID):DeactivateAll()
			local xspd = 10 * utility.RandomDirection()
			local yspd = math.random() * 2
			c:GetPositionComponent(EID):SetMovement(CPP.Vec2(xspd, yspd))
			local timer = 60
			base.overrideUpdateFunction = function()
				timer = timer - 1
				if timer <= 0 then
					c.entity:Delete(EID)
				end
			end
		else
			c.entity:Delete(EID)
		end
		return true;
	end

	function base.OnLuaEvent(eid, description)
		for k,v in pairs(base.LuaEventFunctions) do
			v(eid, description)
		end
	end

	function base.OnKeyUp(keyname)

	end

	function base.OnKeyDown(keyname)

	end

	base.EntityInterface = {
		Activate      = function () end,
		IsSolid		  = function () return true;  end,
		IsCollectable = function () return 0;  end,
		IsPlayer = function () return false;  end,
		CanBounce     = function () return false; end, --the 'goomba' property
		CanGrab		  = function () return false; end,
		--This instance being attacked, returns true if attack hit, false if not
		Attack        = function (attack) return base.Attacked(attack); end,  --this instance being attacked
		Land          = function () return 1; end--This instance being landed on
	}

	return base;
end

return BaseEntity.new
