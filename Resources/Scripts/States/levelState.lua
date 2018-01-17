local container = {}
function container.NewState(baseclass)
	local state = baseclass or {}
	state.worldMapName = "WorldMapGrassy.tmx"
	state.fadeIn = false
	state.fadeOut = false

	function state.Initialize()
		state.depth		= state.LEngineData.depth;
		state.parent	= state.LEngineData.parent;
		state.EID		= state.LEngineData.entityID;
		local save = CPP.GameSave("save1")
		if(save:FileExists())then
			save:ReadFromFile()
		end

		state.save = save

		--CPP.interface:LoadMap("Hub.tmx", 0)
		--state.LoadMap("Hub.tmx")
		state.LoadWorldMap()
	end

	function state.Update()
		if(state.fadeIn) then
			local frameIncrement = .01
			state.fadeInPercentage = state.fadeInPercentage + frameIncrement
			if(state.fadeInPercentage > 1)then
				state.fadeInPercentage = 1
			end

			local newLight = CPP.Vec3(0,0,0)
			newLight.x = state.ambientLight.x * state.fadeInPercentage
			newLight.y = state.ambientLight.y * state.fadeInPercentage
			newLight.z = state.ambientLight.z * state.fadeInPercentage
			CPP.interface.light:SetAmbient(newLight)

			if(state.fadeInPercentage == 1)then
				--done fading in
				state.fadeIn = false
			end
		end

		if(state.fadeOut) then
			local frameDecrement = .01
			state.fadeOutPercentage = state.fadeOutPercentage - frameDecrement
			if(state.fadeOutPercentage < 0)then
				state.fadeOutPercentage = 0
			end
			CPP.interface:LogError(state.EID, tostring(state.fadeOutPercentage))

			local newLight = CPP.Vec3(0,0,0)
			newLight.x = state.ambientLight.x * state.fadeOutPercentage
			newLight.y = state.ambientLight.y * state.fadeOutPercentage
			newLight.z = state.ambientLight.z * state.fadeOutPercentage
			CPP.interface.light:SetAmbient(newLight)

			if(state.fadeOutPercentage == 0)then
				--done fading in
				state.fadeOut = false
				CPP.interface:LoadMap(state.newMapName, state.newMapEntranceID, state.OnMapLoad)
				state.lastMap = state.newMapName
			end
		end
	end

	function state.Close()
		state.save:WriteToFile()
	end

	function state.GetSaveData()
		return state.save
	end

	function state.LoadWorldMap()
		local c = CPP.interface
		local onLoad = function(map)
			--local player = CPP.interface:EntityNewPrefab("player", 4*16 20*16, 0, 0, "worldMapLouie.xml" )
			--local playerEID = CPP.interface:EntityNew("player", 4*16, 20*16, 0, 0, "worldMapLouie.lua", {})
			--local cameraEID = CPP.interface:EntityNew("camera", 4*16, 20*16, 0, playerEID, "Camera/playerCamera.lua", {["_PARENT"] = playerEID})


			local playerEID = CPP.interface.entity:New()
			local playerPrefab = "worldMapLouie.xml"
			c:GetPositionComponent(playerEID):SetPositionWorld(CPP.Vec2(4*16, 20*16))
			c:GetSpriteComponent(playerEID):SetDepth(0)
			c.script:CreateEntityPrefab(playerEID, playerPrefab, {})

			local cameraEID = CPP.interface.entity:New()
			local cameraScript = {"Camera/playerCamera.lua"}
			c.script:CreateEntity(cameraEID, cameraScript, {["_PARENT"] = playerEID})
		end
		CPP.interface:LoadMap(state.worldMapName, 0, onLoad)
	end

	function state.PlayEvent(event)
		local activeEntities = CPP.interface.entity:GetActiveEntities()
		CPP.interface:Deactivate(activeEntities)
		local eventFinishCallback = function()
			CPP.interface.Activate(activeEntities)
		end
		event.Play(eventFinishCallback)
	end

	function state.OnMapLoad(map)
		state.fadeInPercentage = 0.0
		state.ambientLight = map:GetAmbientLight()
		local al = state.ambientLight
		state.fadeIn = true
	end

	function state.LoadMap(name, entranceID)
		CPP.interface:LogError(state.EID, "CALLED")
		local entMan = CPP.interface.entity
		entMan:DeactivateAllExcept({state.EID})
		state.newMapName = name
		state.newMapEntranceID = entranceID or 0
		state.fadeOutPercentage = 1.0
		state.ambientLight = CPP.interface.light:GetAmbient()
		state.fadeOut = true
	end

	state.EntityInterface = state.EntityInterface or {}
	state.EntityInterface.GetSaveData = state.GetSaveData
	state.EntityInterface.LoadMap = state.LoadMap

	return state;
end

return container.NewState;
