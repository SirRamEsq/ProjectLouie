local container = {}
function container.NewState(baseclass)
	local state = baseclass or {}
	state.worldMapName = "WorldMapGrassy.tmx"

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
		state.LoadMap("Hub.tmx")
	end

	function state.Update()
	end

	function state.Close()
		state.save:WriteToFile()
	end

	function state.GetSaveData()
		return state.save
	end

	function state.LoadWorldMap()
		CPP.interface:LoadMap(state.worldMapName, 0)
	end

	function state.OnMapLoad(map)
		local layers = CPP.interface:GetLayersWithProperty(map, "_SOLID", true)
		local layerCount = layers:size()
		for i=0, layerCount-1 do
			local layer = layers:at(i)
			if(layer ~= nil)then
				--map:DeleteLayer(layer)
			end
		end

	end

	function state.LoadMap(name, entranceID)
		entranceID = entranceID or 0
		CPP.interface:LoadMap(name, entranceID, state.OnMapLoad)
	end

	state.EntityInterface = state.EntityInterface or {}
	state.EntityInterface.GetSaveData = state.GetSaveData
	state.EntityInterface.LoadMap = state.LoadMap

	return state;
end

return container.NewState;
