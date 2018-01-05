local container = {}
function container.NewState(baseclass)
	local state = baseclass or {}

	function state.Initialize()
		state.depth		= state.LEngineData.depth;
		state.parent		= state.LEngineData.parent;
		state.EID		= state.LEngineData.entityID;
		local save = CPP.GameSave("save1")	
		if(save:FileExists())then
			save:ReadFromFile()
		end

		state.save = save

		CPP.interface:LoadMap("Hub.tmx", 0)
	end

	function state.Update()
	end

	function state.Close()
		state.save:WriteToFile()
	end

	function state.GetSaveData()
		return state.save
	end

	state.EntityInterface = state.EntityInterface or {}
	state.EntityInterface.GetSaveData = state.GetSaveData

	return state;
end

return container.NewState;
