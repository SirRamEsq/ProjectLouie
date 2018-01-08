function NewFallingPlatform(baseclass)
	local platform = baseclass or {}

	platform.c = {}
	platform.c.WIDTH  = 32
	platform.c.HEIGHT = 16
	platform.c.ALARM  = 1
	platform.c.ALARM_OFFSET  = 2
	platform.c.OFFSET_TIME = 2 + math.floor(math.random(5))

	platform.c.FALL_TIME  = 60
	platform.c.FALL_SPEED = 4
	platform.c.GRAVITY    = 0.21875;
	platform.c.MAXSPEED   = 8

	platform.c.DIR_UP   = 0
	platform.c.DIR_DOWN = 1

	platform.falling = false

	platform.respawnY = 30000
	platform.initialCoordinates = {}
	platform.initialCoordinates.x = 0
	platform.initialCoordinates.y = 0

	platform.xspd = 0
	platform.yspd = 0

	platform.spriteOffset     = {}
	platform.spriteOffset.xDefault   = (platform.c.WIDTH/2)
	platform.spriteOffset.yDefault   = (platform.c.HEIGHT/2)
	platform.spriteOffset.x   = platform.spriteOffset.xDefault
	platform.spriteOffset.y   = platform.spriteOffset.yDefault
	platform.spriteOffset.DIR = platform.c.DIR_UP
	platform.spriteOffset.max = platform.spriteOffset.yDefault + 2
	platform.spriteOffset.min = platform.spriteOffset.yDefault - 2

	platform.collision = {} -- require("Utility/collisionSystem.lua")
	platform.timing    = require("Utility/timing.lua")

	function platform.Initialize()
		-----------------------
		--C++ Interface setup--
		-----------------------

		platform.depth        = platform.LEngineData.depth;
		platform.parentEID       = platform.LEngineData.parentEID;
		platform.CPPInterface = CPP.interface
		platform.EID          = platform.LEngineData.entityID;

		platform.CompSprite     = platform.CPPInterface:GetSpriteComponent    (platform.EID);
		platform.CompCollision  = platform.CPPInterface:GetCollisionComponent (platform.EID);
		platform.CompPosition   = platform.CPPInterface:GetPositionComponent  (platform.EID);

		----------------
		--Sprite setup--
		----------------
		platform.spriteRSC = platform.CPPInterface:LoadSpriteResource("SpritePlatform.xml");
		if(platform.spriteRSC==nil) then
			platform.CPPInterface:LogError(platform.EID, "spriteRSC is NIL");
		end

		platform.sprite = platform.CompSprite:AddSprite(platform.spriteRSC, platform.depth)
		platform.sprite:SetOffset(spriteOffset.xDefault, platform.spriteOffset.yDefault)
		platform.sprite:SetAnimation("Stand");
		platform.sprite:SetRotation(0);

		platform.collision.Init(platform.c.WIDTH, platform.c.HEIGHT, platform.CPPInterface, platform.CompCollision, platform.EID);

		platform.timing:SetAlarm(platform.c.ALARM, platform.c.FALL_TIME, platform.OnFall, false) --don't repeat alarms
		platform.timing:SetAlarm(platform.c.ALARM_OFFSET, platform.c.OFFSET_TIME, platform.UpdateSpriteOffset, true) --repeat
		platform.timing:GetAlarm(platform.c.ALARM):Disable();

		platform.movement= CPP.Vec2(0, 0)

		local worldPos = platform.CompPosition:GetPositionWorld()
		platform.initialCoordinates.x = worldPos.x
		platform.initialCoordinates.y = worldPos.y

		platform.CompPosition:SetMaxSpeed(platform.c.MAXSPEED)
	end

	function platform.UpdateSpriteOffset()
		if(platform.spriteOffset.DIR == platform.c.DIR_UP)then
			platform.spriteOffset.y = platform.spriteOffset.y + 1
			if(platform.spriteOffset.y >= platform.spriteOffset.max)then
				platform.spriteOffset.DIR = platform.c.DIR_DOWN
			end
		else
			platform.spriteOffset.y = platform.spriteOffset.y - 1
			if(platform.spriteOffset.y <= platform.spriteOffset.min)then
				platform.spriteOffset.DIR = platform.c.DIR_UP
			end
		end

		platform.sprite:SetOffset(platform.spriteOffset.xDefault, platform.spriteOffset.y)
	end

	function platform.Update()
		if(platform.CompPosition:GetPositionWorld().y > platform.respawnY)then
			platform.Respawn()
		end

		--platform.movement= CPP.Vec2(platform.xspd, platform.yspd)
		--platform.CompPosition:SetMovement(platform.movement);
		platform.movement = platform.CompPosition:GetMovement();
		platform.collision.Update(platform.movement.x, platform.movement.y);

		platform.timing:Update();
	end

	function platform.OnEntityCollision(entityID, packet)

	end

	function platform.Respawn()
		platform.CompPosition:SetPositionLocalY(platform.initialCoordinates.y)
		platform.CompPosition:SetAccelerationY(0)
		platform.CompPosition:SetMovementY(0)
		platform.falling = false
		platform.timing:GetAlarm(platform.c.ALARM_OFFSET):Restart();
	end

	function platform.Land()
		if (platform.falling == false)then
			platform.falling = true;
			platform.sprite:SetOffset(platform.spriteOffset.xDefault, platform.spriteOffset.yDefault)
			platform.timing:GetAlarm(platform.c.ALARM):Restart()
			platform.timing:GetAlarm(platform.c.ALARM_OFFSET):Disable();
		end
	end

	function platform.OnFall()
		platform.respawnY = platform.CPPInterface:GetMap():GetHeightPixels() + platform.initialCoordinates.y
		platform.CompPosition:SetAccelerationY(platform.c.GRAVITY)
	end

	function platform.OnLuaEvent(senderEID, eventString)

	end


	function platform.OnTileCollision(senderEID, eventString)

	end


	platform.EntityInterface            = platform.EntityInterface or {}
	platform.EntityInterface.IsSolid    = function ()       return true; end
	platform.EntityInterface.Land       = platform.Land

	return platform;
end

return NewFallingPlatform;
