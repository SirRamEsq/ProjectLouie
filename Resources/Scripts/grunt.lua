function NewGrunt(baseclass)
	local grunt= baseclass or {}
	--Constants
	grunt.WIDTH=16;
	grunt.HEIGHT=16;
	grunt.GRAVITY=0.21875;
	grunt.JUMPHEIGHT=-5;

	grunt.ySpeed = 0;
	grunt.xSpeed = 0
	grunt.xSpeedMax=2;
	grunt.xSpeedIncrement=.2
	grunt.negative=false;

	grunt.xPos = 0
	grunt.yPos = 0

	grunt.CBOX_PRIME_ID=0;

	grunt.CBOX_X=0;
	grunt.CBOX_Y=0;
	grunt.CBOX_W=16;
	grunt.CBOX_H=16;

	grunt.cboxPrimary=nil;
	grunt.collision = require("Utility/collisionSystem.lua")

	--C++ Interfacing
	grunt.CPPInterface=nil;
	grunt.mySprite=nil;
	grunt.mySpriteComp=nil;
	grunt.myColComp=nil;
	grunt.myPositionComp=nil;
	grunt.EID=0;
	grunt.depth=0;
	grunt.parentEID=0;


	function grunt.Initialize()
		-----------------------
		--C++ Interface setup--
		-----------------------

		grunt.depth          = grunt.LEngineData.depth;
		grunt.parentEID         = grunt.LEngineData.parentEID;
		grunt.CPPInterface   = CPP.interface
		grunt.EID            = grunt.LEngineData.entityID;
		local EID = grunt.EID

		grunt.mySpriteComp   = grunt.CPPInterface:GetSpriteComponent    (EID);
		grunt.myColComp      = grunt.CPPInterface:GetCollisionComponent (EID);
		grunt.myPositionComp = grunt.CPPInterface:GetPositionComponent  (EID);

		----------------
		--Sprite setup--
		----------------
		grunt.spriteRSC = grunt.CPPInterface:LoadSpriteResource("SpriteWhiteGrunt.xml");
		if(grunt.spriteRSC==nil) then
			grunt.CPPInterface:LogError("sprite is NIL");
		end

		grunt.sprite = grunt.spriteRSC:AddSprite(grunt.spriteRSC, grunt.depth)
		grunt.sprite:SetAnimation("Walk");
		grunt.sprite:SetRotation (0);

		grunt.myColComp:SetName(grunt.LEngineData.name)
		grunt.myColComp:SetType(grunt.LEngineData.objType);

		grunt.collision.Init(grunt.WIDTH, grunt.HEIGHT, grunt.CPPInterface, grunt.myColComp);
		grunt.collision.callbackFunctions.TileUp    = grunt.OnTileUp;
		grunt.collision.callbackFunctions.TileDown  = grunt.OnTileDown;
		grunt.collision.callbackFunctions.TileLeft  = grunt.OnTileLeft;
		grunt.collision.callbackFunctions.TileRight = grunt.OnTileRight;

		--Allow tiled to overwrite;
		if grunt.LEngineData.InitializationTable.Solid== nil then grunt.LEngineData.InitializationTable.Solid=true; end
	end

	function grunt.Update()
		if(grunt.negative==true)then
			grunt.xSpeed= grunt.xSpeed - grunt.xSpeedIncrement;
		else
			grunt.xSpeed= grunt.xSpeed + grunt.xSpeedIncrement
		end

		if(grunt.xSpeed<=0)then
			grunt.sprite:SetScalingX(-1);
			if(not grunt.negative)then
				grunt.xSpeed= grunt.xSpeed + grunt.xSpeedIncrement
			end
		else
			grunt.sprite:SetScalingX(1);
			if(grunt.negative)then
				grunt.xSpeed= grunt.xSpeed - grunt.xSpeedIncrement
			end
		end

		if(not grunt.collision.groundTouch)then
			grunt.ySpeed= grunt.ySpeed + grunt.GRAVITY;
		else
			grunt.ySpeed=0;
		end

		if(grunt.xSpeed >= grunt.xSpeedMax)then
			grunt.xSpeed = grunt.xSpeedMax;
		elseif(grunt.xSpeed <= -grunt.xSpeedMax)then
			grunt.xSpeed = -grunt.xSpeedMax;
		end

		grunt.updateVec= CPP.Vec2(grunt.xSpeed, grunt.ySpeed)
		grunt.myPositionComp:SetMovement(grunt.updateVec);
		grunt.collision.Update(grunt.xSpeed, grunt.ySpeed);
	end

	function grunt.OnEntityCollision(entityID, packet)
		--CPPInterface:DeleteEntity(EID);
	end

	function grunt.OnTileCollision(packet)
		local absoluteCoords = grunt.myPositionComp:GetPositionWorldInt();
		grunt.collision.OnTileCollision(packet, grunt.xSpeed, grunt.ySpeed, absoluteCoords.x, absoluteCoords.y);
	end

	function grunt.OnTileDown(newPosition, newAngle)
		--Update position
		newPosition= grunt.myPositionComp:TranslateWorldToLocal(newPosition);
		grunt.myPositionComp:SetPositionLocalY(newPosition.y);
	end

	function grunt.OnTileRight(newPosition)
		newPosition= grunt.myPositionComp:TranslateWorldToLocal(newPosition);
		grunt.myPositionComp:SetPositionLocalX(newPosition.x);
		grunt.negative=true;
	end

	function grunt.OnTileLeft(newPosition)
		newPosition= grunt.myPositionComp:TranslateWorldToLocal(newPosition);
		grunt.myPositionComp:SetPositionLocalX(newPosition.x);
		grunt.negative=false;
	end

	function grunt.OnTileUp(newPosition)
		grunt.myPositionComp:TranslateWorldToLocal(newPosition);
		grunt.myPositionComp:SetPositionLocalY(newPosition.y);
		if (grunt.ySpeed<0) then
			grunt.ySpeed=0;
		end
	end

	function grunt.OnLuaEvent(senderEID, eventString)

	end
	grunt.EntityInterface = grunt.EntityInterface or {}
	grunt.EntityInterface.IsSolid     = function ()   return true; end


	return grunt
end

return NewGrunt;
