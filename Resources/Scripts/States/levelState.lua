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

		CPP.interface:LoadMap("Hub.tmx", 0)
		--state.LoadMap("Hub.tmx")
		--state.LoadWorldMap()
	end

	function state.Update()
		if(state.fadeIn) then
			local frameIncrement = .001
			state.fadeInPercentage = state.fadeInPercentage + frameIncrement
			if(state.fadeInPercentage > 1)then
				state.fadeInPercentage = 1
			end

			local r = state.ambientLight.x * state.fadeInPercentage
			local g = state.ambientLight.y * state.fadeInPercentage
			local b = state.ambientLight.z * state.fadeInPercentage

			CPP.interface:SetAmbientLight(r, g, b)
			if(state.fadeInPercentage == 1)then
				--done fading in
				state.fadeIn = false
			end
		end

		if(state.fadeOut) then
			local frameDecrement = .001
			state.fadeOutPercentage = state.fadeOutPercentage - frameDecrement
			if(state.fadeOutPercentage < 0)then
				state.fadeOutPercentage = 0
			end

			local r = state.ambientLight.x * state.fadeOutPercentage
			local g = state.ambientLight.y * state.fadeOutPercentage
			local b = state.ambientLight.z * state.fadeOutPercentage

			CPP.interface:SetAmbientLight(r, g, b)
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
		local onLoad = function(map)
			--local player = CPP.interface:EntityNewPrefab("player", 4*16 20*16, 0, 0, "worldMapLouie.xml" )
			local playerEID = CPP.interface:EntityNew("player", 4*16, 20*16, 0, 0, "worldMapLouie.lua", {})
			local cameraEID = CPP.interface:EntityNew("camera", 4*16, 20*16, 0, playerEID, "Camera/playerCamera.lua", {})
		end
		CPP.interface:LoadMap(state.worldMapName, 0, onLoad)
	end

	function state.PlayEvent(event)
		local activeEntities = CPP.interface:GetActiveEntities()
		CPP.interface:Deactivate(activeEntities)
		local eventFinishCallback = function()
			CPP.interface.Activate(activeEntities)
		end
		event.Play(eventFinishCallback)
	end

	function state.OnMapLoad(map)
		local layers = CPP.interface:GetLayersWithProperty(map, "_SOLID", true)
		for k,v in pairs(layers) do
			if(v ~= nil)then
				--map:DeleteLayer(v)
			end
		end
		state.fadeInPercentage = 0.0
		state.ambientLight = map.GetAmbientLight()
		state.fadeIn = true
	end

	function state.LoadMap(name, entranceID)
		---local entMan = CPP.interface:entityManager
		---entMan:DeactivateEntitiesExcept({state.EID})
		state.newMapName = name
		state.newMapEntranceID = entranceID
		state.fadeOutPercentage = 1.0
		--state.ambientLight = CPP.interface:GetAmbientLight()
		--state.fadeOut = true
	end

	state.EntityInterface = state.EntityInterface or {}
	state.EntityInterface.GetSaveData = state.GetSaveData
	state.EntityInterface.LoadMap = state.LoadMap

	return state;
end

return container.NewState;
