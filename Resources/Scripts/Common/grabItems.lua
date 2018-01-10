--[[
--TO USE:
--C.WIDTH and C.HEIGHT Should be set before calling Init
--
--Can specify a property 'itemLayerProperty' to use as the property to search for
--uses [bool]'hasItems' by default
--
--will increment class.items.coinCount
--]]

local container = {}
function container.NewItemCollector(baseclass)
	local class = baseclass or {}

	class.items = {}
	class.items.coinCount = 0
	class.SoundCoin = "smw_coin.wav"

	--laconic access
	local t = class.items

	function t.GetCoin(coinValue)
		t.coinCount = t.coinCount + coinValue
		CPP.interface:PlaySound(class.SoundCoin, 100)
		return true
	end

	function t.RemoveItemFromLayer(layer, tx, ty)
		layer:SetTile(tx,ty, 0)
		layer:UpdateRenderArea(CPP.Rect(tx,ty, 1,1))
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
		local itemLayers = CPP.interface:GetLayersWithProperty(t.currentMap, itemProperty, true)
		if(itemLayers ~= nil) then
			--if not empty
			if next(itemLayers) ~= nil then
				local shape = CPP.Rect(0,0,w,h)
				t.box = collision:AddCollisionBox(shape, 240);
				t.box:CheckForTiles()
				t.box:RegisterEveryTileCollision()

				for k,v in pairs(itemLayers)do
					if(v ~= nil)then
						t.box:CheckForLayer(v, t.GetItem)
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
