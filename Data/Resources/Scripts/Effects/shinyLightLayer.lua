--[[
--
-- This script will grab a tile layer and flicker its alpha to make it look
-- somewhat like light
--
--]]
local container = {}
function container.New(baseclass)
	local class = baseclass or {}

	function class.Initialize()
		local c = CPP.interface
		local initData = class.LEngineData.InitializationTable
		local EID = class.LEngineData.entityID
		local lightLayerName = initData.lightLayer or "lightFG"

		local currentMap = c:GetMap()
		local lightLayer = currentMap:GetTileLayer(lightLayerName)
		if(lightLayer == nil) then
			c:LogError(EID, "Light layer is NIL!")
		end

		class.lightLayer = lightLayer
		class.layerAlpha = lightLayer:GetAlpha()
		class.lightIncrement = .05
		class.percentage = 0
		class.increasing = true
	end

	function class.Update()
		local newAlpha = class.layerAlpha + (class.lightIncrement * class.percentage)
		local alphaDifference = newAlpha - class.layerAlpha
		newAlpha = class.layerAlpha + (alphaDifference * math.random())
		class.lightLayer:SetAlpha(newAlpha)


		if class.increasing then
			class.percentage = class.percentage + 0.1
		else
			class.percentage = class.percentage - 0.1
		end

		if class.percentage <= 0 then
			class.increasing = true
			class.percentage = 0
		elseif class.percentage >= 1 then
			class.increasing = false
			class.percentage = 1
		end

	end


	return class;
end

return container.New
