--[[
--TO USE:
--C.WIDTH and C.HEIGHT Should be set before calling Init
--
--Can specify a property 'itemLayerProperty' to use as the property to search for
--uses [bool]'hasItems' by default
--
--will increment class.items.coinCount
--
--Outstanding bugs:
--Collision will only register one item per frame
--]]

local container = {}
function container.NewItemCollector(baseclass)
	local class = baseclass or {}

	class.items = {}
	class.items.coinCount = 0

	--laconic access
	local t = class.items

	function t.GetCoin(coinValue)
		t.coinCount = t.coinCount + coinValue	
		return true
	end

	function t.RemoveItemFromLayer(layer, tx, ty)
		layer:SetTile(tx,ty, 0)
		layer:UpdateRenderArea(CPP.Rect(tx,ty, 0,0))
	end

	function t.GetItem(packet)
		local tx = packet:GetTileX()
		local ty = packet:GetTileY()
		local layer = packet:GetLayer()
		local itemTaken = false
		tileID = layer:GetTile(tx,ty)
		--returns string, empty string if no property
		local isCoin = layer:GetTileProperty(tileID, "coinValue")
		if isCoin ~= "" then
			itemTaken = t.GetCoin(isCoin)
		end

		if itemTaken then
			t.RemoveItemFromLayer(layer,tx,ty)
		end

	end

	function t.ItemInit()
		local initData = class.LEngineData.InitializationTable
		local EID = class.LEngineData.entityID
		local itemProperty = initData.itemLayerProperty or "hasItems"

		local collision = CPP.interface:GetCollisionComponent(EID)
		local w = class.C.WIDTH 
		local h = class.C.HEIGHT 

		t.currentMap = CPP.interface:GetMap()
		local itemLayers = CPP.interface:GetLayersWithProperty(itemProperty, true)
		if(itemLayers ~= nil) then
			if(itemLayers:empty() == false)then
				local box = CPP.Rect(0,0,w,h)
				--Create collision box only when item layers exist
				t.boxID = collision:AddCollisionBox(box, 240);
				collision:CheckForTiles(t.boxID);

				local layerCount = itemLayers:size()
				for i=0, layerCount-1 do
					local itemLayer = itemLayers:at(i)
					if(itemLayer ~= nil)then
						collision:CheckForLayer(t.boxID, itemLayer, t.GetItem)
					end
				end
			end
		end
	end

	function t.ItemUpdate()
	end

	table.insert(class.InitFunctions, t.ItemInit)

	return class
end

return container.NewItemCollector
