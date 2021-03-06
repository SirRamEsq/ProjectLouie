local container = {}
function container.NewFallingHat(baseclass)
	local hat = baseclass or {}
	--Constants
	hat.WIDTH=8;
	hat.HEIGHT=8;


	--Variables
	hat.xPos=0;
	hat.yPos=0;

	hat.myColComp=nil;
	hat.CompPosition=nil;
	hat.CompParticle=nil;
	hat.EID=0;

	hat.particleCreator=nil;
	hat.particleVelocitySuperMin = nil;
	hat.particleVelocitySuperMax = nil;
	hat.timer = 4

	hat.c = {}
	hat.c.GRAVITY=0.21875;
	hat.c.VELOCITY_Y = -6
	hat.c.VELOCITY_X = 1

	function hat.Initialize()
		-----------------------
		--C++ Interface setup--
		-----------------------
		local c = CPP.interface
		hat.EID			= hat.LEngineData.entityID;
		local EID = hat.EID

		hat.CompSprite		= c:GetSpriteComponent   (EID);
		hat.CompPosition	= c:GetPositionComponent (EID);
		hat.CompParticle	= c:GetParticleComponent (EID);
		hat.dir = hat.LEngineData.InitializationTable.direction or 1

		hat.spriteRsc	 = c:LoadSpriteResource("louieHat.xml");
		hat.sprite = hat.CompSprite:AddSprite(hat.spriteRsc)
		hat.animation = "hat"
		hat.rotation = 0
		hat.rotationSpeed = 2.5

		hat.sprite:SetAnimation		(hat.animation);
		hat.sprite:SetAnimationSpeed(0);
		hat.sprite:SetRotation		(0);

		hat.deleteTimer = 600

		--------------------
		--Particle Effects--
		--------------------
		hat.particleLifetime = 90;

		hat.particleCreator = hat.CompParticle:AddParticleCreator(0, hat.particleLifetime);

		local particlePositionMin = CPP.Vec2(-8, -8);
		local particlePositionMax = CPP.Vec2( 8,  8);

		local particleVelocityMin = CPP.Vec2(-0.25, -0.25);
		local particleVelocityMax = CPP.Vec2(0.25,  -1.00);

		local particleAccelMin= CPP.Vec2(-0.0025, 0.01);
		local particleAccelMax= CPP.Vec2( 0.0025, 0.01);

		hat.particleCreator:SetPosition(particlePositionMin, particlePositionMax);
		hat.particleCreator:SetVelocity(particleVelocityMin, particleVelocityMax);
		hat.particleCreator:SetAcceleration(particleAccelMin, particleAccelMax);
		hat.particleCreator:SetParticlesPerFrame(.25);
		hat.particleCreator:SetScalingX(2,2);
		hat.particleCreator:SetScalingY(2,2);
		hat.particleCreator:SetColor(0.9, 0.2, 0.2, 1,	1, .1, .1, 1);
		
		hat.particleCreator:SetShape(4);
		hat.particleCreator:SetEffect(2);
		hat.particleCreator:Start();
		hat.CompPosition:SetMovement(CPP.Vec2(hat.c.VELOCITY_X * hat.dir, hat.c.VELOCITY_Y));
		hat.CompPosition:SetAcceleration(CPP.Vec2(0,hat.c.GRAVITY));
	end

	function hat.Update()
		hat.sprite:SetRotation(hat.rotation);
		hat.rotation = hat.rotation + hat.rotationSpeed
		hat.rotation = hat.rotation % 360

		hat.deleteTimer = hat.deleteTimer - 1
		if(hat.deleteTimer <=0)then
			CPP.interface:EntityDelete(hat.EID)
		end
	end

	return hat
end

return container.NewFallingHat
