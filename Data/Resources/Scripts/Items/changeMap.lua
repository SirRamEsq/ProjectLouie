function NewChangeMap(baseclass)
	local cMap= baseclass or {}

	function cMap.Initialize()
		-----------------------
		--C++ Interface setup--
		-----------------------

		cMap.depth          = cMap.LEngineData.depth;
		cMap.parentEID      = cMap.LEngineData.parentEID;
		cMap.EID            = cMap.LEngineData.entityID;
		local EID = cMap.EID
		local state = CPP.interface:EntityGetInterface(cMap.LEngineData.stateEID)
		cMap.state = state

		cMap.spriteComp = CPP.interface:GetSpriteComponent    (EID);
		cMap.posComp	= CPP.interface:GetPositionComponent  (EID);
		cMap.colComp	= CPP.interface:GetCollisionComponent  (EID);

		cMap.spriteName = cMap.LEngineData.InitializationTable["sprite"] or "vortex.xml"
		cMap.animationName = cMap.LEngineData.InitializationTable["animation"] or ""
		cMap.rotationSpeed = cMap.LEngineData.InitializationTable["rotationSpeedd"] or 2.5
		cMap.animationSpeed = cMap.LEngineData.InitializationTable["animationSpeed"] or 0.1
		cMap.map = cMap.LEngineData.InitializationTable["map"] or "Hub.tmx"

		----------------
		--Sprite setup--
		----------------
		cMap.spriteRSC = CPP.interface:LoadSpriteResource(cMap.spriteName);
		if(cMap.spriteRSC ==nil) then
			CPP.interface:LogError(EID, "sprite is NIL");
		end
		cMap.sprWidth = cMap.spriteRSC:Width()
		cMap.sprHeight = cMap.spriteRSC:Height()

		--Logical origin is as at the top left; (0,0) is top left
		--Renderable origin is at center;       (-width/2, -width/2) is top left
		--To consolodate the difference, use the Vec2 offset (WIDTH/2, HEIGHT/2)
		cMap.sprite = cMap.spriteComp:AddSprite(cMap.spriteRSC, cMap.depth);
		cMap.sprite:SetAnimation(cMap.animationName);
		cMap.sprite:SetAnimationSpeed(cMap.animationSpeed);
		cMap.sprite:SetRotation (0);
		cMap.rotation = 0

		-------------------
		--Collision setup--
		-------------------
		cMap.cbox = {}
		cMap.cbox.shape = CPP.Rect(0, 0, cMap.sprWidth, cMap.sprHeight)
		cMap.cbox.box = cMap.colComp:AddCollisionBox(cMap.cbox.shape)
		cMap.colComp:SetPrimaryCollisionBox(cMap.cbox.box)
		cMap.cbox.box:CheckForEntities()
	end

	function cMap.Update()
		if cMap.rotationSpeed ~= 0 then
			cMap.rotation = cMap.rotation + cMap.rotationSpeed
			cMap.sprite:SetRotation (cMap.rotation);
		end
	end

	function cMap.OnEntityCollision(entityID, packet)
		cMap.rotation = 0
	end

	function cMap.OnLuaEvent(senderEID, eventString)

	end

	function cMap.Activate()
		cMap.state.LoadMap(cMap.map, 0)
	end

	cMap.EntityInterface = cMap.EntityInterface or {}
	cMap.EntityInterface.IsSolid     = function ()   return false; end
	cMap.EntityInterface.Activate     = function ()   cMap.Activate(); end

	return cMap
end

return NewChangeMap;
