function NewFallingPlatform(baseclass)
	local platform = baseclass or {}

	platform.C = {}
	platform.C.WIDTH  = 32
	platform.C.HEIGHT = 16
	platform.C.ALARM  = 1
	platform.C.ALARM_OFFSET  = 2
	platform.C.OFFSET_TIME = 2 + math.floor(math.random(5))

	platform.C.FALL_TIME  = 60
	platform.C.FALL_SPEED = 4
	platform.C.GRAVITY    = 0.21875;
	platform.C.MAXSPEED   = 8

	platform.C.DIR_UP   = 0
	platform.C.DIR_DOWN = 1

	platform.falling = false

	platform.respawnY = 30000
	platform.initialCoordinates = {}
	platform.initialCoordinates.x = 0
	platform.initialCoordinates.y = 0

	platform.xspd = 0
	platform.yspd = 0

	platform.spriteOffset     = {}
	platform.spriteOffset.xDefault   = 0
	platform.spriteOffset.yDefault   = 0
	platform.spriteOffset.x   = platform.spriteOffset.xDefault
	platform.spriteOffset.y   = platform.spriteOffset.yDefault
	platform.spriteOffset.DIR = platform.C.DIR_UP
	platform.spriteOffset.max = platform.spriteOffset.yDefault + 2
	platform.spriteOffset.min = platform.spriteOffset.yDefault - 2

	platform.timing    = (require("Utility/timing.lua"))()

	local Init = function()
		-----------------------
		--C++ Interface setup--
		-----------------------

		platform.CPPInterface = CPP.interface
		platform.EID          = platform.LEngineData.entityID;

		platform.CompSprite     = platform.CPPInterface:GetSpriteComponent    (platform.EID);
		platform.CompPosition   = platform.CPPInterface:GetPositionComponent  (platform.EID);

		platform.depth = platform.CompSprite:GetDepth()

		----------------
		--Sprite setup--
		----------------
		platform.spriteRSC = platform.CPPInterface:LoadSpriteResource("SpritePlatform.xml");
		if(platform.spriteRSC==nil) then
			platform.CPPInterface:LogError(platform.EID, "spriteRSC is NIL");
		end

		platform.sprite = platform.CompSprite:AddSprite(platform.spriteRSC, platform.depth)
		platform.sprite:SetOffset(platform.spriteOffset.xDefault, platform.spriteOffset.yDefault)
		platform.sprite:SetAnimation("Stand");
		platform.sprite:SetRotation(0);

		platform.timing:SetAlarm(platform.C.ALARM, platform.C.FALL_TIME, platform.OnFall, false) --don't repeat alarms
		platform.timing:SetAlarm(platform.C.ALARM_OFFSET, platform.C.OFFSET_TIME, platform.UpdateSpriteOffset, true) --repeat
		platform.timing:GetAlarm(platform.C.ALARM):Disable();

		platform.movement= CPP.Vec2(0, 0)

		local worldPos = platform.CompPosition:GetPositionWorld()
		platform.initialCoordinates.x = worldPos.x
		platform.initialCoordinates.y = worldPos.y

		platform.CompPosition:SetMaxSpeed(platform.C.MAXSPEED)
	end

	function platform.UpdateSpriteOffset()
		if(platform.spriteOffset.DIR == platform.C.DIR_UP)then
			platform.spriteOffset.y = platform.spriteOffset.y + 1
			if(platform.spriteOffset.y >= platform.spriteOffset.max)then
				platform.spriteOffset.DIR = platform.C.DIR_DOWN
			end
		else
			platform.spriteOffset.y = platform.spriteOffset.y - 1
			if(platform.spriteOffset.y <= platform.spriteOffset.min)then
				platform.spriteOffset.DIR = platform.C.DIR_UP
			end
		end

		platform.sprite:SetOffset(platform.spriteOffset.xDefault, platform.spriteOffset.y)
	end

	local Update = function()
		if(platform.CompPosition:GetPositionWorld().y > platform.respawnY)then
			platform.Respawn()
		end

		--platform.movement= CPP.Vec2(platform.xspd, platform.yspd)
		--platform.CompPosition:SetMovement(platform.movement);
		platform.movement = platform.CompPosition:GetMovement();

		platform.timing:Update();
	end

	function platform.OnEntityCollision(entityID, packet)

	end

	function platform.Respawn()
		platform.CompPosition:SetPositionLocalY(platform.initialCoordinates.y)
		platform.CompPosition:SetAccelerationY(0)
		platform.CompPosition:SetMovementY(0)
		platform.falling = false
		platform.timing:GetAlarm(platform.C.ALARM_OFFSET):Restart();
	end

	function platform.Land()
		if (platform.falling == false)then
			platform.falling = true;
			platform.sprite:SetOffset(platform.spriteOffset.xDefault, platform.spriteOffset.yDefault)
			platform.timing:GetAlarm(platform.C.ALARM):Restart()
			platform.timing:GetAlarm(platform.C.ALARM_OFFSET):Disable();
		end
	end

	function platform.OnFall()
		platform.respawnY = platform.CPPInterface:GetMap():GetHeightPixels() + platform.initialCoordinates.y
		platform.CompPosition:SetAccelerationY(platform.C.GRAVITY)
	end

	platform.InitFunctions = platform.InitFunctions or {}
	platform.UpdateFunctions = platform.UpdateFunctions or {}
	table.insert(platform.InitFunctions, Init)
	table.insert(platform.UpdateFunctions, Update)
	platform.EntityInterface            = platform.EntityInterface or {}
	platform.EntityInterface.IsSolid    = function ()       return true; end
	platform.EntityInterface.Land       = platform.Land

	return platform;
end

return NewFallingPlatform;
