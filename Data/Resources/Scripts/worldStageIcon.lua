local container = {}
local imGuiFlags = require("Utility/imGuiWindowFlags.lua")

container.New = function(base)
	local class = base or {}
	class.C = class.C or {}
	class.C.WIDTH = 16
	class.C.HEIGHT = 16
	class.font = "ebFonts/wisdom.ttf"
	class.fontSize = 30

	class.windowX = 0
	class.windowY = 0
	class.windowPosRatio = 1
	class.render = false

	local Init = function()
		local c = CPP.interface
		local le = class.LEngineData
		local eid = le.entityID
		local stageName = le.InitializationTable.stageName
		if(stageName == nil)then
			c.LogError("Parameter 'stageName' is not defined!")
		end
		class.LoadFont()
		class.SetResolution()

		class.CompPosition = c:GetPositionComponent(eid)
		class.CompSprite = c:GetSpriteComponent(eid)
		local spr = class.CompSprite
		class.depth = spr:GetDepth()
		class.spriteRSC	 = c:LoadSpriteResource("worldMapStage.xml")
		class.sprite = spr:AddSprite(class.spriteRSC)
		class.sprite:SetAnimation("Flash")
		class.sprite:SetAnimationSpeed(.15)

		class.EID = eid
		class.stageName = stageName
	end

	function class.SetResolution()
		local c = CPP.interface
		class.resolution = c:GetResolution()
	end

	function class.LoadFont()
		local popFont = CPP.ImGui.PushFont(class.font, class.fontSize)

		if(popFont)then
			CPP.ImGui.PopFont(1)
		end
	end

	function class.OnEntityCollision(entityID, packet)
		local other= CPP.interface:EntityGetInterface(entityID)
		--if other.isPlayer() then
			class.render = true
		--end
	end

	function class.PushWindowRight()
		local increment = .02
		class.windowPosRatio = math.min(1, class.windowPosRatio + increment)
	end

	function class.PushWindowLeft()
		local increment = .02
		class.windowPosRatio = math.max(0,class.windowPosRatio - increment)
	end

	function class.SlideFromRight(left)
		local right = class.resolution.x + 1
		if left > right then
			return right
		end
		local difference = right - left
		local increment = math.floor(difference * class.windowPosRatio)
		return left + increment
	end

	local Update = function()
		if class.render then
			class.PushWindowLeft()
		else
			class.PushWindowRight()
		end

		if class.windowPosRatio < 1 then
			class.DisplayStageStatus()
		end

		class.render = false
	end

	function class.DisplayStageStatus()

		local windowFlags = imGuiFlags.NoTitleBar + imGuiFlags.NoResize +
		imGuiFlags.NoMove + imGuiFlags.AlwaysAutoResize

		--World Position
		CPP.ImGui.SetContext(1)

		--push style options
		CPP.ImGui.PushStyleColorWindowBG(CPP.Color(0.2, 0.2, 0.2, 1))

		--create window
		CPP.ImGui.BeginFlags(class.stageName, windowFlags)

		CPP.ImGui.Text("Highest Coin Score: " .. tostring(219))
		CPP.ImGui.Text("Complete? " .. ":)")

		--end and pop style
		local winSize = CPP.ImGui.GetWindowSize()
		CPP.ImGui.End()
		CPP.ImGui.PopStyleColor(1)

		class.windowX = class.resolution.x - winSize.x
		class.windowY = 0
		local target = CPP.Vec2(class.windowX, class.windowY)

		target.x = class.SlideFromRight(target.x)
		CPP.ImGui.SetWindowPos(class.stageName, class.CompPosition:GetPositionWorld(), 0)

		CPP.ImGui.SetContext(0)
	end

	table.insert(class.InitFunctions, Init)
	table.insert(class.UpdateFunctions, Update)

	local Activate = function()
		local state = CPP.interface:EntityGetInterface(class.LEngineData.stateEID)
		state.LoadMap(class.stageName, 0)
	end

	class.EntityInterface = class.EntityInterface or {}
	class.EntityInterface.Activate = Activate

	return class
end

return container.New
