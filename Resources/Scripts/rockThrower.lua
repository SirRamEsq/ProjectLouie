function NewRockThrower(baseclass)
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
	class.timing = require("Utility/timing.lua")

	local function Init()
		local LED = class.LEngineData
		local iface = CPP.interface
		class.depth        = LED.depth;
		class.parentEID    = LED.parentEID;
		class.EID          = LED.entityID;

		class.CompSprite   = iface:GetSpriteComponent   (class.EID)
		class.CompCol      = iface:GetCollisionComponent(class.EID)
		class.CompPos   = iface:GetPositionComponent (class.EID)

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
		class.sprite:SetAnimation(class.C.animationStand)
	end

	local function Update()
		class.timing:Update()
	end

	table.insert(class.InitFunctions, Init)
	table.insert(class.UpdateFunctions, Update)


	return class
end

return NewRockThrower
