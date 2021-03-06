local container = {}
function container.New(baseclass)
	local bat = baseclass or {}
	bat.C = bat.C or {}
	bat.C.WIDTH = 24
	bat.C.HEIGHT = 24

	local Init = function()
		local eid = bat.LEngineData.entityID
		local spriteComp = CPP.interface:GetSpriteComponent(eid)
		local spriteResource = CPP.interface:LoadSpriteResource("bat.xml")

		if( spriteResource==nil ) then
			CPP.interface:LogError(eid, "spriteResource is NIL")
		end

		local sprite	= spriteComp:AddSprite(spriteResource)

		math.randomseed(os.clock()*100000000000)
		local newImage =  math.random(0, 5)
		local newImageSpeed = sprite:GetAnimationSpeed() - (math.random() / 16)
		sprite:SetAnimation		("Fly")
		sprite:SetAnimationSpeed(newImageSpeed)
		sprite:SetImage         (newImage)
		sprite:SetRotation		(0)
	end

	local Update = function()

	end

	function bat.OnEntityCollision(eid, desc)

	end

	bat.InitFunctions = bat.InitFunctions or {}
	bat.UpdateFunctions = bat.UpdateFunctions or {}
	table.insert(bat.InitFunctions, Init)
	table.insert(bat.UpdateFunctions, Update)

	return bat
end

return container.New
