local container = {}
function container.NewRockThrower(baseclass)
	local class = baseclass or {}

	class.C = class.C or {}
	class.C.spriteName = "rockThrower.xml"
	class.C.animationStand = "Stand"
	class.C.animationThrow = "Throw"
	class.C.DIR_LEFT = -1
	class.C.DIR_RIGHT = 1
	class.C.RELOAD_TIME = 150
	class.dir = class.C.DIR_LEFT
	class.alarm = {}
	class.alarm.reload = 1
	class.timing = (require("Utility/timing.lua"))()

	local function Init()
		local LED = class.LEngineData
		local iface = CPP.interface
		class.parentEID    = LED.parentEID;
		class.EID          = LED.entityID;

		class.CompSprite   = iface:GetSpriteComponent   (class.EID)
		class.CompCol      = iface:GetCollisionComponent(class.EID)
		class.CompPos   = iface:GetPositionComponent (class.EID)

		class.depth = class.CompSprite:GetDepth()

		local spriteName = class.C.spriteName
		class.spriteRSC = iface:LoadSpriteResource(spriteName)
		if(class.spriteRSC == nil)then
			iface:LogError("Sprite named '" .. spriteName .. "' is NIL")
		end

		class.sprite = class.CompSprite:AddSprite(class.spriteRSC, class.depth, 0, 0)
		class.sprite:SetAnimation(class.C.animationStand)

		class.dir=LED.InitializationTable.direction or "right"
		if class.dir == "left" then
			class.dir = class.C.DIR_LEFT
		else
			class.dir = class.C.DIR_RIGHT
		end
		class.sprite:SetScalingX(class.dir)

		class.timing:SetAlarm(class.alarm.reload, class.C.RELOAD_TIME, class.OnReload, true)
	end

	function class.OnReload()
		class.sprite:AnimationPlayOnce(class.C.animationThrow, class.Throw)
	end

	function class.Throw()
		local c = CPP.interface
		class.sprite:SetAnimation(class.C.animationStand)

		local newEID = c.entity:New()
		local prefabName = "rock.xml"
		local speed	={x=(4 * class.dir),  y=-0.5}
		local pos = class.CompPos:GetPositionWorld()
		pos.y = pos.y + 8
		c:GetPositionComponent(newEID):SetPositionWorld(pos)
		c:GetSpriteComponent(newEID):SetDepth(class.depth)
		c.script:CreateEntityPrefab(newEID, prefabName, {initialSpeed=speed})
	end

	local function Update()
		class.timing:Update()
	end

	table.insert(class.InitFunctions, Init)
	table.insert(class.UpdateFunctions, Update)

	return class
end

return container.NewRockThrower
