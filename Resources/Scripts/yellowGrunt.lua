function NewYellowGrunt(baseclass)
	local class = baseclass or {}
	--Constants
	class.WIDTH=16
	class.HEIGHT=16
	class.GRAVITY=0.21875
	class.JUMPHEIGHT=-5

	class.ySpeed = 0
	class.xSpeed = 0
	class.xSpeedMax=2
	class.xSpeedIncrement=.2
	class.negative=false

	class.DIRECTION_LEFT="left"
	class.DIRECTION_RIGHT="right"
	class.DIRECTION=0

	class.xPos = 0
	class.yPos = 0

	class.CBOX_PRIME_ID=0

	class.CBOX_X=0
	class.CBOX_Y=0
	class.CBOX_W=16
	class.CBOX_H=16

	class.RELOAD_TIME=60
	class.SHOOT_TIME=20

	class.cboxPrimary=nil
	class.timing    = require("Utility/timing.lua")


	class.ALARM_NAME1=1
	class.ALARM_NAME2=2

	class.arrowsFired=0

	--C++ Interfacing
	class.CPPInterface=nil
	class.mySprite=nil
	class.mySpriteComp=nil
	class.mySpriteID=0
	class.myColComp=nil
	class.myPositionComp=nil
	class.EID=0
	class.depth=0
	class.parentEID=0


	function class.Initialize()
		-----------------------
		--C++ Interface setup--
		-----------------------

		class.depth        = class.LEngineData.depth
		class.parentEID       = class.LEngineData.parentEID
		class.CPPInterface = CPP.interface
		class.EID          = class.LEngineData.entityID
		local EID = class.EID

		class.mySpriteComp   = class.CPPInterface:GetSpriteComponent    (EID)
		class.myColComp      = class.CPPInterface:GetCollisionComponent (EID)
		class.myPositionComp = class.CPPInterface:GetPositionComponent  (EID)

		----------------
		--Sprite setup--
		----------------
		class.spriteRSC = CPP.interface:LoadSpriteResource("SpriteYellowGrunt.xml")
		if(class.spriteRSC==nil) then
			class.CPPInterface:LogError("sprite is NIL")
		end

		--Logical origin is as at the top left (0,0) is top left
		--Renderable origin is at center       (-width/2, -width/2) is top left
		--To consolodate the difference, use the Vec2 offset (WIDTH/2, HEIGHT/2)
		class.sprite = class.mySpriteComp:AddSprite(class.spriteRSC, class.depth)
		class.sprite:SetAnimation("Stand")
		class.sprite:SetRotation(0)

		class.dir = class.LEngineData.InitializationTable.direction or "right"
		if class.dir == "left" then
			class.DIRECTION=class.DIRECTION_LEFT
		else
			class.DIRECTION=class.DIRECTION_RIGHT
		end

		class.timing:SetAlarm(class.ALARM_NAME1, class.SHOOT_TIME, class.OnShoot, false) --don't repeat alarms
		class.timing:SetAlarm(class.ALARM_NAME2, class.RELOAD_TIME, class.OnReload, false) --don't repeat alarms
		class.timing:GetAlarm(class.ALARM_NAME2):Disable()
	end

	function class.OnShoot()
		--create entity and listen to events
		local entityArrow
		local position=class.myPositionComp:GetPositionWorld()
		class.arrowsFired=class.arrowsFired+1

		local name = ""
		local scriptName = "Items/Projectiles/arrow.lua"
		entityArrow = class.CPPInterface:EntityNew(
		name, position.x, position.y, class.depth, 0, scriptName,
		{direction = class.DIRECTION, shooterEID = class.EID})

		class.CPPInterface:EventLuaObserveEntity(class.EID, entityArrow)

		--Update sprite
		class.sprite:SetAnimation("Shoot")

		--Update Alarm
		local alarm=class.timing:GetAlarm(class.ALARM_NAME2)
		alarm:Restart()
	end

	function class.OnReload()
		--Update Sprite
		class.sprite:SetAnimation("Stand")

		--Update Alarm
		local alarm=class.timing:GetAlarm(class.ALARM_NAME1)
		alarm:Restart()
	end

	function class.Update()
		class.timing:Update()
	end

	function class.OnLuaEvent(senderEID, eventString)
	end

	class.EntityInterface = class.EntityInterface or {}
	class.EntityInterface.CanBounce   = function ()       return true end

	return class
end

return NewYellowGrunt
