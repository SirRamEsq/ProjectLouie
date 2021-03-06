--[[
Implemented
Platform Riding
Roll
Long Jump
Wall Slide
Wall Jump
Skid jump

To Implement
KLONOA style enemy/item grab

Each map will have challenges
pink - harm no ememies
Green - Collect 7 emeralds
Grey - Collect Nothing
Blue - Time
Red - Use no special abilities (roll)

]]--

local imGuiFlags = require("Utility/imGuiWindowFlags.lua")
local fadeOut = require("Utility/fadeOutLayer.lua")


local container = {}
function container.NewLouie(baseclass)
	function SetConstants(louie)
		--Constants
		louie.c = {}
		--Keys
		louie.c.K_UP = "up"
		louie.c.K_DOWN = "down"
		louie.c.K_LEFT = "left"
		louie.c.K_RIGHT = "right"
		louie.c.K_ACTIVATE = "activate"
		louie.c.K_ATTACK = "attack"

		louie.c.TILE_WIDTH=16
		louie.c.TILE_HEIGHT=16

		louie.c.MAXSPEED=16
		louie.c.MAXHEALTH=10

		louie.c.COL_WIDTH=18 --WIDTH of object sprite
		louie.c.COL_HEIGHT=32 --HEIGHT of object sprite
		louie.c.WIDTH=18 --WIDTH of object sprite
		louie.c.HEIGHT=32 --HEIGHT of object sprite
		louie.c.SIDEJUMP_XSPD = 0.1

		louie.C.WIDTH = louie.c.COL_WIDTH
		louie.C.HEIGHT = louie.c.COL_HEIGHT

		louie.c.GRAVITY=0.21875
		louie.c.SLOPE_GRAVITY=0.15
		louie.c.JUMPHEIGHT=-6
		--slightly higher than a regular jump
		louie.c.JUMPHEIGHT_BOX = louie.c.JUMPHEIGHT - 1
		louie.c.ACCELERATION=.046875*2
		louie.c.ACCELERATION_AIR= louie.c.ACCELERATION
		louie.c.DEACCELERATION=.3
		louie.c.ACCELERATION_TOP=4 --Max Speed Louie can acheive through normal acceleration
		louie.c.ROLL_SPEED= louie.c.ACCELERATION_TOP+1
		louie.c.ROLL_TIMER=15
		louie.c.ROLL_COOLDOWN=30
		louie.c.MIN_ROLL_SPEED=3
		louie.rollTimer=0
		louie.spinTimer=0
		louie.c.SPIN_COOLDOWN=80
		--The value spinTimer must be less than in order to exit the spin
		louie.spinTimerExitSpin=40
		--shorter spin in air
		louie.spinTimerExitSpinAir=60

		louie.c.FRICTION_AIR=.1
		louie.c.FRICTION_MODIFER=0.46875*2 --The friction of a tile is multiplied by this constant to get the actual friction value
		louie.c.MAX_STEPUP_PIXELS = 12

		louie.c.WALLJUMP_LOCK=10
		louie.c.WALLJUMP_XSPD=5
		louie.c.WALLJUMP_YSPD=5
		louie.c.WALLJUMP_GRAVITY=louie.c.GRAVITY/4
		louie.c.WALLJUMP_YSPD_MAX=2

		louie.c.STATE_NORMAL	= 0
		louie.c.STATE_ROLL		= 1
		louie.c.STATE_WALLSLIDE	= 3
		louie.c.STATE_CLIMB		= 4
		louie.c.STATE_SPIN		= 5

		louie.c.FACING_LEFT=-1
		louie.c.FACING_RIGHT=1

		louie.c.KNOCKBACK_SPEED_X=2.5
		louie.c.KNOCKBACK_SPEED_Y=-3
	end

	local louie = baseclass or {}
	SetConstants(louie)

	function louie.InitVariables()
		--Useful functions
		local result
		local common
		local common = require("Utility/commonFunctions.lua")
		louie.common = common

		--General Movement Variables
		louie.health= 2
		louie.xspd=0
		louie.yspd=0
		louie.groundSpeed=0
		louie.prevGroundSpeed=0 -- Ground speed of previous frame
		louie.tileFriction=0.046875
		louie.inputLock=false
		louie.lockTimer=0

		louie.attackLock=false --character locked from being hit
		louie.angle=0
		louie.angleSigned=0
		louie.facingDir=louie.c.FACING_RIGHT

		louie.currentState= louie.c.STATE_NORMAL

		louie.isDecelerating = false

		--CLIMBING
		louie.climb = {}
		louie.climb.SPEED = 2
		louie.climb.LAYER = nil
		louie.climb.LAYER_NAME = "CLIMB"

		--Input
		louie.input = require("Utility/input.lua")

		--C++ Interfacing
		louie.mainSprite = nil
		louie.mainSpriteRoll = nil
		louie.baldSprite = nil
		louie.baldSpriteRoll = nil
		louie.currentSprite = 0
		louie.currentSpriteRoll = 0

		louie.CompSprite=nil
		louie.CompPosition=nil
		louie.CompCollision=nil

		louie.EID=0
		louie.depth=0
		louie.parentEID=0
		louie.currentMap = nil

		--Height Maps
		louie.HMAP_HORIZONTAL= 0
		louie.HMAP_VERTICAL	= 1

		--Entity collision
		louie.entityCollision = {}
		louie.entityCollision.primary= {}
		louie.entityCollision.primary.box = nil
		louie.entityCollision.primary.shape = nil

		louie.entityCollision.grabCollision = {}
		louie.entityCollision.grabCollision.box = nil
		louie.entityCollision.grabCollision.ID = 21
		louie.entityCollision.grabCollision.timer={}
		louie.entityCollision.grabCollision.timer.max=30
		louie.entityCollision.grabCollision.timer.current=0

		--Collision
		--louie.tileCollision = require("Utility/tileCollisionSystemNew.lua")

		--Sound Effects
		louie.SoundJump = "smw_jump.wav"
		louie.SoundFireball = "smw_fireball.wav"
	end

	function louie.MainInitialize()
		louie.InitVariables()

		-----------------------
		--C++ Interface setup--
		-----------------------
		louie.EID	= louie.LEngineData.entityID
		louie.name = louie.LEngineData.name
		louie.objType = louie.LEngineData.objType


		louie.parentEID= 0

		--[[
		if(louie.LEngineData.debugMode)then
			local mobdebug = require("Utility/mobdebug.lua")
			CPP.interface:LogError(louie.EID, tostring(result))
			CPP.interface:LogError(louie.EID, tostring(mobdebug))
			mobdebug.start("localhost")
		end
		]]--

		local EID = louie.EID
		CPP.interface:ListenForInput(EID, louie.c.K_UP)
		CPP.interface:ListenForInput(EID, louie.c.K_DOWN)
		CPP.interface:ListenForInput(EID, louie.c.K_LEFT)
		CPP.interface:ListenForInput(EID, louie.c.K_RIGHT)
		CPP.interface:ListenForInput(EID, louie.c.K_ACTIVATE)
		CPP.interface:ListenForInput(EID, louie.c.K_ATTACK)
		CPP.interface:ListenForInput(EID, "cheat")
		louie.input.RegisterKey( louie.c.K_UP   )
		louie.input.RegisterKey( louie.c.K_DOWN )
		louie.input.RegisterKey( louie.c.K_LEFT )
		louie.input.RegisterKey( louie.c.K_RIGHT)
		louie.input.RegisterKey( louie.c.K_ACTIVATE)
		louie.input.RegisterKey( louie.c.K_ATTACK)

		louie.CompCollision = CPP.interface:GetCollisionComponent(EID)
		louie.CompScript    = CPP.interface:GetScriptComponent(EID)
		louie.CompSprite	= CPP.interface:GetSpriteComponent(EID)
		louie.CompPosition  = CPP.interface:GetPositionComponent(EID)
		louie.CompLight		= CPP.interface:GetLightComponent(EID)

		louie.depth = louie.CompSprite:GetDepth()

		--[[
		--Lights
		CPP.interface:SetAmbientLight(.25, .25, .3)
		local light = louie.CompLight:CreatePointLight()
		light.color = CPP.Vec3(2.5, 1, 1)
		light.distance = 150
		light.noise = .1
		--light.pos =  CPP.Vec3(-100,0,20)
		light.pos =  CPP.Vec3(-100,0,21)
		louie.light = light

		local light2 = louie.CompLight:CreatePointLight()
		light2.color = CPP.Vec3(1, 2.5, 1)
		light2.distance = 100
		light2.noise = .1
		light2.pos =  CPP.Vec3(80,-20,0)
		louie.light2 = light2
		]]--

		----------------
		--Sprite setup--
		----------------
		louie.mainSpriteRSC	 = CPP.interface:LoadSpriteResource("SpriteLouie.xml")
		louie.mainSpriteRollRSC = CPP.interface:LoadSpriteResource("SpriteLouieRoll.xml")
		louie.baldSpriteRSC	 = CPP.interface:LoadSpriteResource("SpriteLouieBald.xml")
		louie.baldSpriteRollRSC = CPP.interface:LoadSpriteResource("SpriteLouieBaldRoll.xml")

		louie.coinSpriteRSC	= CPP.interface:LoadSpriteResource("coin.xml")
		louie.coinAnimation = "Spin"

		if( louie.mainSpriteRSC==nil ) then
			CPP.interface:LogError(louie.EID, "sprite is NIL")
		end
		if( louie.baldSpriteRSC==nil ) then
			CPP.interface:LogError(louie.EID, "bald sprite is NIL")
		end

		--Logical origin is as at the top left (0,0) is top left
		--Renderable origin is at center				(-width/2, -width/2) is top left
		--To consolodate the difference, use the Vec2 offset (WIDTH/2, HEIGHT/2)
		louie.mainSprite	 = louie.CompSprite:AddSprite(louie.mainSpriteRSC,	louie.depth)
		louie.mainSpriteRoll = louie.CompSprite:AddSprite(louie.mainSpriteRollRSC,	louie.depth)
		louie.mainSpriteRoll:SetOffset(0, 15)

		louie.baldSprite     = louie.CompSprite:AddSprite(louie.baldSpriteRSC,	louie.depth)
		louie.baldSpriteRoll = louie.CompSprite:AddSprite(louie.baldSpriteRollRSC,	louie.depth)
		louie.baldSpriteRoll:SetOffset(0, 15)

		louie.mainSprite:SetAnimation		("Stand")
		louie.mainSprite:SetAnimationSpeed  (1)
		louie.mainSprite:SetRotation		(0)

		louie.mainSpriteRoll:SetAnimation		("Roll")
		louie.mainSpriteRoll:SetAnimationSpeed  (1)
		louie.mainSpriteRoll:SetRotation		(0)
		louie.mainSpriteRoll:Render				(false)

		-----------------------
		--Collision for tiles--
		-----------------------
		--louie.tileCollision.Init(louie.c.COL_WIDTH, louie.c.COL_HEIGHT, louie.EID)
		louie.tile.up.callback	= louie.OnTileUp
		louie.tile.down.callback  = louie.OnTileDown
		louie.tile.left.callback  = louie.OnTileLeft
		louie.tile.right.callback = louie.OnTileRight

		--Short boxes
		local shortLeft = CPP.Rect(0,16,1,2)
		local shortRight = CPP.Rect(louie.C.WIDTH,16,-1,2)
		louie.tile.shortLeft = louie.CompCollision:AddCollisionBox(shortLeft)
		louie.tile.shortRight = louie.CompCollision:AddCollisionBox(shortRight)
		louie.tile.shortLeft:CheckForTiles()
		louie.tile.shortRight:CheckForTiles()
		louie.tile.shortLeft:Deactivate()
		louie.tile.shortRight:Deactivate()
		louie.tile.CheckForSolidLayers(louie.tile.shortLeft, louie.tile.left.Handle)
		louie.tile.CheckForSolidLayers(louie.tile.shortRight,louie.tile.right.Handle)
		louie.tile.UseShortBoxes = function()
			louie.tile.shortLeft:Activate()
			louie.tile.shortRight:Activate()
			louie.tile.left.cbox:Deactivate()
			louie.tile.right.cbox:Deactivate()
		end
		louie.tile.UseNormalBoxes = function()
			louie.tile.left.cbox:Activate()
			louie.tile.right.cbox:Activate()
			louie.tile.shortLeft:Deactivate()
			louie.tile.shortRight:Deactivate()
		end

		--Primary collision
		louie.entityCollision.primary = {}
		louie.entityCollision.primary.shape= CPP.Rect(0, 0, louie.c.COL_WIDTH, louie.c.COL_HEIGHT)
		louie.entityCollision.primary.box= louie.CompCollision:AddCollisionBox(louie.entityCollision.primary.shape)
		local ebox = louie.entityCollision.primary.box
		ebox:SetOrder(30)
		ebox:CheckForEntities()
		louie.CompCollision:SetPrimaryCollisionBox(ebox)

		--[[Grab collision
		louie.entityCollision.grabCollision.box = CPP.Rect(louie.c.COL_WIDTH/2, louie.c.COL_HEIGHT/2, louie.c.COL_WIDTH/2,	1)
		louie.CompCollision:AddCollisionBox(louie.entityCollision.grabCollision.box, louie.entityCollision.grabCollision.ID, 30)
		louie.CompCollision:CheckForEntities(louie.entityCollision.grabCollision.ID)
		--]]

		louie.currentMap = CPP.interface:GetMap()
		louie.climb.LAYER = louie.currentMap:GetTileLayer(louie.climb.LAYER_NAME)

		louie.gui = {}
		louie.gui.font = "ebFonts/wisdom.ttf"
		louie.gui.fontSize = 20
		louie.LoadFont()

		--Load save data
		local state = CPP.interface:EntityGetInterface(louie.LEngineData.stateEID)
		louie.saveData = state.GetSaveData()
		local coins = 0
		if(louie.saveData:ExistsInt("Coins"))then
			coins = louie.saveData:GetInt("Coins")
		end
		louie.items.coinCount = coins
	end


	function louie.OnKeyDown(keyname)
		if(keyname == "cheat") then louie.InputJump() end
		louie.input.OnKeyDown(keyname)
	end

	function louie.OnKeyUp(keyname)
		louie.input.OnKeyUp(keyname)
	end

	function louie.SetCollisionBoxes()
		if(louie.currentState == louie.c.STATE_ROLL)then
			louie.tile:UseShortBoxes()
		else
			louie.tile:UseNormalBoxes()
		end
	end

	function louie.MainUpdate()
		if(louie.groundSpeed == 0)then
			louie.isDecelerating = false
		end
		louie.saveData:SetInt("Coins", louie.items.coinCount)
		louie.SetCollisionBoxes()
		louie.Climb()
		louie.WallSlide()
		louie.UpdateInputs()

		louie.LandOnPlatform()
		louie.ApplySlopeFactor()
		louie.ApplyFrictionGravity()

		louie.HandleInput()
		louie.Animate()

		louie.UpdateCPP()
		louie.UpdateGUI()

		louie.PrepareForNextFrame()
	end

	function louie.AnimateSpin()
		louie.currentSpriteRoll:Render(false)
		louie.currentSprite:Render    (true)
		if louie.tile.groundTouch then
			louie.currentSprite:SetAnimation("Spin")
			louie.currentSprite:SetAnimationSpeed(1)
		else
			louie.currentSprite:SetAnimation("AirSpin")
			louie.currentSprite:SetAnimationSpeed(1)
		end
	end

	function louie.AnimateNormal()
		louie.currentSpriteRoll:Render(false)
		louie.currentSprite:Render    (true)
		local newImgSpd=math.abs(louie.groundSpeed)/16
		if(newImgSpd>2)then
			newImgSpd=2
		end

		if(louie.groundSpeed > louie.c.ACCELERATION)then
			louie.currentSprite:SetAnimation("Walk")
			louie.currentSprite:SetAnimationSpeed(newImgSpd)
			louie.facingDir = louie.c.FACING_RIGHT

		elseif(louie.groundSpeed < -(louie.c.ACCELERATION))then
			louie.currentSprite:SetAnimation("Walk")
			louie.currentSprite:SetAnimationSpeed(newImgSpd)
			louie.facingDir = louie.c.FACING_LEFT

		elseif(louie.groundSpeed==0)then
			--if only one ground collision is touching
			if louie.common.XOR(louie.tile.groundTouchLeft, louie.tile.groundTouchRight)then
				louie.currentSprite:SetAnimation("Teeter")
				louie.currentSprite:SetAnimationSpeed(.5)
			else
				louie.currentSprite:SetAnimation("Stand")
				louie.currentSprite:SetAnimationSpeed(0)
			end
		end

		if(louie.isDecelerating) then
			if(louie.tile.groundTouch)then
				louie.currentSprite:SetAnimation("Skid")
			end
		end

		louie.currentSprite:SetScalingX(louie.facingDir)
		louie.currentSprite:SetScalingY(1)

		if(louie.tile.groundTouch)then
			louie.currentSprite:SetRotation(-louie.angle)
		else
			louie.currentSprite:SetAnimation("Jump")
			louie.currentSprite:SetRotation (0)
		end

	end

	function louie.AnimateOther()
		louie.currentSpriteRoll:Render(false)
		louie.currentSprite:Render    (true)

		louie.currentSprite:SetAnimation	  ("Stand")
		louie.currentSprite:SetAnimationSpeed (0)
		louie.currentSprite:SetScaling		  (louie.facingDir, 1)

		if(louie.tile.groundTouch)then
			louie.currentSprite:SetRotation(-louie.angle)
		else
			louie.currentSprite:SetRotation(0)
		end

		if(louie.currentState == louie.c.STATE_WALLSLIDE)then
			louie.currentSprite:SetAnimation("WallSlide")
		end
	end

	function louie.AnimateRoll()
		local csr = louie.currentSpriteRoll
		csr:SetScaling(louie.facingDir, 1)
		csr:SetRotation((360*(louie.lockTimer/louie.c.ROLL_TIMER)) * -1 * louie.facingDir)
		csr:SetAnimation("Roll")

		csr:Render(true)
		louie.currentSprite:Render(false)
	end

	function louie.AnimateClimb()
		louie.currentSprite:SetScaling(1, 1)
		louie.currentSprite:SetRotation(0)
		louie.currentSprite:SetAnimation("Climb")
		if(louie.xspd == 0 and louie.yspd == 0)then
			louie.currentSprite:SetAnimationSpeed(0)
		else
			louie.currentSprite:SetAnimationSpeed(.1)
		end

		louie.currentSpriteRoll:Render(false)
		louie.currentSprite:Render(true)
	end

	function louie.Animate()
		if (louie.health <= 1) then
			louie.currentSprite = louie.baldSprite
			louie.currentSpriteRoll = louie.baldSpriteRoll
			louie.mainSprite:Render    (false)
			louie.mainSpriteRoll:Render(false)
		else
			louie.currentSprite = louie.mainSprite
			louie.currentSpriteRoll = louie.mainSpriteRoll
			louie.baldSprite:Render    (false)
			louie.baldSpriteRoll:Render(false)
		end

		if	(louie.currentState == louie.c.STATE_ROLL)	then
			louie.AnimateRoll()

		elseif(louie.currentState == louie.c.STATE_NORMAL)then
			louie.AnimateNormal()

		elseif(louie.currentState == louie.c.STATE_CLIMB)then
			louie.AnimateClimb()

		elseif(louie.currentState == louie.c.STATE_SPIN)then
			louie.AnimateSpin()

		else
			louie.AnimateOther()
		end

	end

	function louie.CanClimb()
		if(louie.climb.LAYER == nil)then return end
		local world = louie.CompPosition:GetPositionWorld():Round()

		return louie.climb.LAYER:HasTile( (world.x + (louie.c.WIDTH/2))/16, (world.y + (louie.c.HEIGHT/2))/16 )
	end

	function louie.Climb()
		if(louie.currentState == louie.c.STATE_CLIMB)then
			if(louie.CanClimb() == false)then
				louie.ChangeState(louie.c.STATE_NORMAL)
			end
		end
	end

	function louie.WallSlide()
		if((louie.tile.groundTouch==true)and(louie.currentState == louie.c.STATE_WALLSLIDE))then
			louie.ChangeState(louie.c.STATE_NORMAL)
		end
	end


	function louie.UpdateInputs()
		louie.input.Update()
	end

	function louie.LandOnPlatform()
		if( (louie.tile.groundTouch) and (not louie.tile.previous.groundTouch) ) then
			if( math.abs(louie.angleSigned)<25 )then
				if(louie.angleSigned>=0)then
					louie.groundSpeed = louie.xspd
				else
					louie.groundSpeed = louie.xspd
				end
			elseif( math.abs(louie.angleSigned)<=45 ) then
				if(math.abs(louie.xspd) > math.abs(louie.yspd))then
					louie.groundSpeed = louie.xspd
				elseif(louie.angleSigned>0)then
					louie.groundSpeed = louie.yspd*-1*0.5*math.abs((math.cos(math.rad(louie.angle))))
				else
					louie.groundSpeed=louie.yspd*0.5*math.abs((math.cos(math.rad(louie.angle))))
				end

			else
				if(louie.angleSigned>0)then
					louie.groundSpeed = louie.yspd*-1--*math.abs((math.sin(math.rad(angle))))
				else
					louie.groundSpeed = louie.yspd--*math.abs((math.sin(math.rad(angle))))
				end
			end
			louie.yspd=0
		end
	end

	function louie.ApplySlopeFactor()
		if(  ( (louie.angle>30)and(louie.angle<180) ) or ( (louie.angle<330)and(louie.angle>180) )	)then
			local extraSpeed = louie.c.SLOPE_GRAVITY * math.sin(math.rad(louie.angle))*-1

			local zeroGSPD=(louie.groundSpeed==0)
			local positiveGSPD=(louie.groundSpeed>0)
			local newGSPD
			louie.groundSpeed = louie.groundSpeed + extraSpeed
			newGSPD=(louie.groundSpeed>0)
			if( (positiveGSPD~=newGSPD) and (not zeroGSPD) )then
				--lock input if direction changes
				--LockInput(30)
			end
		end
	end

	function louie.ApplyFrictionGravity()
		local friction --Friction value used for this frame
		local gravityFrame --Gravity for this frame
		if(louie.currentState==louie.c.STATE_CLIMB)then
			return
		end
		if(louie.currentState==louie.c.STATE_WALLSLIDE)then
			gravityFrame=louie.c.WALLJUMP_GRAVITY
		else
			gravityFrame=louie.c.GRAVITY
		end
		friction= louie.c.FRICTION_MODIFER * louie.tileFriction

		--GRAVITY
		if (not louie.tile.groundTouch) then
			louie.yspd = louie.yspd+gravityFrame
			louie.mainSprite:SetRotation(0)
			louie.angle=0
			if(louie.currentState==louie.c.STATE_WALLSLIDE)then
				if(louie.yspd > louie.c.WALLJUMP_YSPD_MAX)then
					louie.yspd = louie.c.WALLJUMP_YSPD_MAX
				end
			end
		end

		if ((not louie.input.key[louie.c.K_LEFT]) and (not louie.input.key[louie.c.K_RIGHT]) and (louie.tile.groundTouch))then
			friction=friction*5
		end
		if ( ((not louie.input.key[louie.c.K_LEFT]) and (not louie.input.key[louie.c.K_RIGHT])) or (louie.inputLock) )then
			--IF TOUCHING THE GROUND
			if(louie.tile.groundTouch)then
				if(louie.groundSpeed>0)then
					if(friction>=louie.groundSpeed)then
						louie.groundSpeed=0
					else
						louie.groundSpeed = louie.groundSpeed - friction
					end

				elseif(louie.groundSpeed<0)then
					if(louie.groundSpeed>=(friction*-1) )then
						louie.groundSpeed=0
					else
						louie.groundSpeed = louie.groundSpeed + friction
					end
				end
				--IF NOT TOUCHING THE GROUND
			else
				if(louie.xspd>0)then
					if(louie.c.FRICTION_AIR>=louie.xspd)then
						louie.xspd = 0
					else
						louie.xspd = louie.xspd - louie.c.FRICTION_AIR
					end

				elseif(louie.xspd < 0)then
					if(louie.xspd >= (louie.c.FRICTION_AIR*-1))then
						louie.xspd = 0
					else
						louie.xspd= louie.xspd + louie.c.FRICTION_AIR
					end
				end
			end
		end
	end

	function louie.LockInput(frames)
		louie.lockTimer=frames
		louie.inputLock=true
	end

	function louie.UnlockInput()
		louie.inputLock=false
		louie.lockTimer=0
		if(louie.currentState == louie.c.STATE_ROLL)then
			if(louie.tile.upTouch == true)then
				louie.ChangeState(louie.c.STATE_ROLL)
				if louie.input.key[louie.c.K_LEFT] then
					louie.facingDir = louie.c.FACING_LEFT
				elseif louie.input.key[louie.c.K_RIGHT] then
					louie.facingDir = louie.c.FACING_RIGHT
				end
				return false
			end
		end
		louie.currentState=louie.c.STATE_NORMAL
		return true
	end

	function louie.UpdateLock()
		if(louie.lockTimer>0)then
			louie.lockTimer= louie.lockTimer - 1
		end
		if(louie.lockTimer==0)then
			if louie.UnlockInput() then
				louie.lockTimer=-1
			end
		end
		if(louie.rollTimer>0)then
			louie.rollTimer = louie.rollTimer - 1
		end
		if(louie.spinTimer>0)then
			if louie.tile.groundTouch then
				if louie.spinTimer <= louie.spinTimerExitSpin then
					if louie.currentState == louie.c.STATE_SPIN then
						louie.ChangeState(louie.c.STATE_NORMAL)
					end
				end
			else
				if louie.spinTimer <= louie.spinTimerExitSpinAir then
					if louie.currentState == louie.c.STATE_SPIN then
						louie.ChangeState(louie.c.STATE_NORMAL)
					end
				end
			end
			louie.spinTimer = louie.spinTimer - 1
		end
	end

	function louie.InputJump()
		if louie.tile.previous.upTouch == true then return end
		CPP.interface:PlaySound(louie.SoundJump, 100)
		if(math.abs(louie.angleSigned)<25)then
			louie.yspd = louie.c.JUMPHEIGHT
		else
			local yCos=math.abs(math.cos(math.rad(louie.angle)))
			local xSin=math.sin(math.rad(louie.angle))
			louie.yspd = (louie.c.JUMPHEIGHT * yCos) + ((louie.groundSpeed/4) * yCos)
			louie.xspd = (louie.c.JUMPHEIGHT * xSin) - (math.abs(louie.groundSpeed) * xSin)
		end

		louie.groundSpeed=0
		louie.angle=0
		louie.tile.groundTouch=false
		if(louie.currentState==louie.c.STATE_ROLL)then --long jump
			louie.xspd = louie.xspd * 1.5
		elseif(louie.isDecelerating)then --side jump
			if(math.abs(louie.xspd) > 2)then
				louie.yspd = louie.yspd * 1.25
				louie.xspd = louie.c.SIDEJUMP_XSPD * louie.facingDir * -1
			end
		end

		louie.CompScript:BroadcastEvent("JUMP")
		louie.UnlockInput()
	end

	function louie.InputWallJump()
		CPP.interface:PlaySound(louie.SoundJump, 100)
		louie.xspd = louie.c.WALLJUMP_XSPD * louie.facingDir
		louie.yspd = -louie.c.WALLJUMP_YSPD

		louie.ChangeState(louie.c.STATE_NORMAL)
		louie.LockInput(louie.c.WALLJUMP_LOCK)
	end

	function louie.BoxJump()
		louie.yspd = math.min(louie.c.JUMPHEIGHT, louie.yspd * -1)
		if(not louie.input.key[louie.c.K_UP])then
			louie.yspd = -3
		end

		louie.groundSpeed=0
		louie.angle=0
		louie.tile.groundTouch=false

		--Up Key not Pressed
		if (not louie.input.key[louie.c.K_UP]) then
			louie.JumpCancel()
		end

		if(louie.currentState==louie.c.STATE_ROLL)then --long jump
			louie.xspd = louie.xspd * 1.5
		end

		louie.CompScript:BroadcastEvent("JUMP")
		louie.UnlockInput()
	end

	function louie.ChangeState(newState)
		louie.tile.UseNormalBoxes()
		if(newState == louie.c.STATE_NORMAL) then
			louie.UnlockInput()

		elseif(newState == louie.c.STATE_ROLL) then
			--Need to be moving fast enough to trigger a roll
			--or already be rolling
			--if (louie.c.currentState ~= louie.c.STATE_ROLL) and (math.abs(louie.groundSpeed) >= louie.c.MIN_ROLL_SPEED) then
			louie.tile.UseShortBoxes()
			louie.LockInput(louie.c.ROLL_TIMER)
			--else
			--louie.ChangeState(louie.c.STATE_NORMAL)
			--return
			--end

		elseif(newState==louie.c.STATE_WALLSLIDE) then
			louie.xspd=0
			if(louie.yspd<0)then
				louie.yspd=0
			end
		elseif(newState==louie.c.STATE_ATTACK) then
			--do nothing i Guess
		elseif(newState==louie.c.STATE_CLIMB) then
			louie.xspd=0
			louie.yspd=0
			louie.tile.groundTouch=false
		end
		if (newState==nil)then
			CPP.interface:LogError(louie.EID, "State is NIL")
			assert(nil, "NEWSTATE IS NIL")
		end

		louie.currentState = newState
	end

	function louie.InputHorizontal(direction)
		local absGS=math.abs(louie.groundSpeed)
		local absX= math.abs(louie.xspd)
		local movDir= (louie.groundSpeed>=0)

		--enable louie to change direction when stopped
		if(louie.xspd == 0) then louie.facingDir = direction end

		if(movDir==false)then
			movDir=-1
		else
			movDir=1
		end

		if(louie.groundSpeed == 0)then
			movDir = direction
		end

		louie.isDecelerating = false

		--UPDATE GSPD (GROUND)
		if(louie.tile.groundTouch) then
			if(movDir==direction) then --Add friction to the ground speed (slowing him faster) if moving against momentum
				if(absGS<louie.c.ACCELERATION_TOP)then
					louie.groundSpeed= louie.groundSpeed + (louie.c.ACCELERATION * direction)
				end
			else
				louie.groundSpeed= louie.groundSpeed + (louie.c.DEACCELERATION * direction)
				louie.isDecelerating = true
			end
		end

		--UPDATE XSPD (AIR)
		if(not louie.tile.groundTouch) then
			if(louie.currentState == louie.c.STATE_CLIMB)then
				louie.xspd = direction * louie.climb.SPEED
				louie.facingDir = direction
			else
				movDir= (louie.xspd>=0)
				if(movDir==false)then
					movDir=-1
				else
					movDir=1
				end
				if(movDir==direction) then
					if(absX<louie.c.ACCELERATION_TOP)then
						louie.xspd= louie.xspd + (louie.c.ACCELERATION_AIR * direction)
					end
				else
					louie.xspd= louie.xspd + ((louie.c.ACCELERATION_AIR + louie.c.FRICTION_AIR) * direction)
					louie.isDecelerating = true
				end
			end
		end

	end

	function louie.JumpCancel()
		if(louie.yspd<(-2))then
			louie.yspd=(-2)
		end
	end

	function louie.HandleInput()
		--Up Pressed
		if (louie.input.keyPress[louie.c.K_UP]) then
			if(louie.currentState == louie.c.STATE_WALLSLIDE)then
				louie.InputWallJump()

			elseif(louie.currentState == louie.c.STATE_CLIMB)then
				louie.yspd = -louie.climb.SPEED

			elseif(louie.CanClimb())then
				louie.ChangeState(louie.c.STATE_CLIMB)
				louie.yspd = -louie.climb.SPEED

			elseif (louie.tile.groundTouch) then
				louie.InputJump()
			end
		end
		--Up Released
		if ( (louie.input.keyRelease[louie.c.K_UP]) and (not louie.tile.groundTouch) ) then
			louie.JumpCancel()

			if(louie.currentState == louie.c.STATE_CLIMB) then
				louie.yspd = 0
			end
		end

		----------------------------------------------------------------------

		--Right Pressed
		if ( (louie.input.key[louie.c.K_RIGHT]) and (not louie.inputLock) ) then
			if((louie.tile.previous.rightTouch==true)and(not louie.tile.groundTouch)and(louie.yspd>=0))then
				louie.facingDir = louie.c.FACING_LEFT --face opposite way of wall slide
				louie.ChangeState(louie.c.STATE_WALLSLIDE)
			else
				louie.InputHorizontal(louie.c.FACING_RIGHT)
			end
		end
		--Right Released
		if (louie.input.keyRelease[louie.c.K_RIGHT]) then
			if(louie.currentState == louie.c.STATE_WALLSLIDE)then
				if(louie.facingDir == louie.c.FACING_LEFT)then
					louie.ChangeState(louie.c.STATE_NORMAL)
				end
			end
			if(louie.currentState == louie.c.STATE_CLIMB) then
				louie.xspd = 0
			end
		end

		----------------------------------------------------------------------

		--Left Pressed
		if ( (louie.input.key[louie.c.K_LEFT]) and (not louie.inputLock) ) then
			if((louie.tile.previous.leftTouch==true) and(not louie.tile.groundTouch)and(louie.yspd>=0))then
				louie.facingDir = louie.c.FACING_RIGHT --face opposite way of wall slide
				louie.ChangeState(louie.c.STATE_WALLSLIDE)
			else
				louie.InputHorizontal(louie.c.FACING_LEFT)
			end
		end
		--Left Released
		if (louie.input.keyRelease[louie.c.K_LEFT]) then
			if(louie.currentState==louie.c.STATE_WALLSLIDE)then
				if(louie.facingDir==louie.c.FACING_RIGHT)then
					louie.ChangeState(louie.c.STATE_NORMAL)
				end
			end
			if(louie.currentState == louie.c.STATE_CLIMB) then
				louie.xspd = 0
			end
		end

		----------------------------------------------------------------------

		--Down Pressed
		if ( (louie.input.key[louie.c.K_DOWN]) and (not louie.inputLock) ) then
			if((louie.currentState==louie.c.STATE_NORMAL)and(louie.tile.groundTouch==true)and(louie.rollTimer==0))then
				louie.ChangeState(louie.c.STATE_ROLL)
				louie.rollTimer = louie.c.ROLL_COOLDOWN
			elseif(louie.currentState==louie.c.STATE_CLIMB)then
				louie.yspd = louie.climb.SPEED
			end
		end
		--Down Released
		if ( (louie.input.keyRelease[louie.c.K_DOWN]) ) then
			if(louie.currentState == louie.c.STATE_CLIMB) then
				louie.yspd = 0
			end
		end

		-----------------------------------------------------------------------
		--Attack Pressed
		if ( (louie.input.key[louie.c.K_ATTACK]) and (not louie.inputLock) ) then
			if((louie.currentState~=louie.c.STATE_ROLL)and(louie.currentState ~= louie.c.STATE_CLIMB) and (louie.spinTimer == 0) )then
				louie.ChangeState(louie.c.STATE_SPIN)
				louie.spinTimer = louie.c.SPIN_COOLDOWN
			end
		end
	end

	function louie.UpdateCPP()
		local speedDampenX=1
		local speedDampenY=1

		if(louie.currentState==louie.c.STATE_ROLL)then
			louie.groundSpeed = louie.c.ROLL_SPEED * louie.facingDir
		end

		if(louie.groundSpeed > louie.c.MAXSPEED) then
			louie.groundSpeed = louie.c.MAXSPEED
		elseif(louie.groundSpeed < (-louie.c.MAXSPEED)) then
			louie.groundSpeed=-louie.c.MAXSPEED
		end

		if(louie.xspd > louie.c.MAXSPEED) then
			louie.xspd = louie.c.MAXSPEED
		elseif(louie.xspd < (-louie.c.MAXSPEED)) then
			louie.xspd = -louie.c.MAXSPEED
		end

		if(louie.yspd > louie.c.MAXSPEED) then
			louie.yspd = louie.c.MAXSPEED
		elseif(louie.yspd < (-louie.c.MAXSPEED)) then
			louie.yspd = -louie.c.MAXSPEED
		end

		if(louie.tile.groundTouch) then
			louie.xspd = louie.groundSpeed
			louie.yspd = 0
			speedDampenX=math.cos(math.rad(louie.angle))
		else
			speedDampenX=1
			speedDampenY=1
		end

		if(louie.tile.groundTouch==false)then
			louie.xspd = louie.xspd
			louie.yspd = louie.yspd
			CPP.interface.position:SetParent(louie.EID, louie.parentEID)
		end
		updateVec=CPP.Vec2((louie.xspd*speedDampenX), (louie.yspd*speedDampenY))
		louie.CompPosition:SetMovement(updateVec)
	end

	function louie.LoadFont()
		local popFont = CPP.ImGui.PushFont(louie.gui.font, louie.gui.fontSize)

		if(popFont)then
			CPP.ImGui.PopFont(1)
		end
	end
	function louie.UpdateGUI()
		local popFont = CPP.ImGui.PushFont(louie.gui.font, louie.gui.fontSize)

		local resolution = CPP.interface:GetResolution()
		local windowFlags = imGuiFlags.NoTitleBar + imGuiFlags.NoResize + imGuiFlags.NoMove + imGuiFlags.AlwaysAutoResize

		--no background
		CPP.ImGui.PushStyleColorWindowBG(CPP.Color(0,0,0, 0))
		CPP.ImGui.PushStyleColorText(CPP.Color(.8,.2,.2,2))
		louie.guiName = "louieGUI"

		CPP.ImGui.BeginFlags(louie.guiName, windowFlags)
		CPP.ImGui.Sprite(louie.coinSpriteRSC, louie.coinAnimation, 0)
		CPP.ImGui.SameLine()
		CPP.ImGui.Text(" X " .. tostring(louie.items.coinCount))
		local winSize = CPP.ImGui.GetWindowSize()
		CPP.ImGui.End()
		CPP.ImGui.PopStyleColor(2)

		--Center Window
		local guiPosition = CPP.Vec2(( resolution.x/2) - (winSize.x/2), 0)
		CPP.ImGui.SetWindowPos(louie.guiName, guiPosition, 0)

		if(popFont)then
			CPP.ImGui.PopFont(1)
		end
	end

	function louie.PrepareForNextFrame()
		louie.UpdateLock()

		Vec2d = louie.CompPosition:GetPositionWorld()
		local xx=Vec2d.x
		local yy=Vec2d.y

		if(louie.currentState==louie.c.STATE_WALLSLIDE)then
			if((louie.tile.previous.rightTouch==false)and(louie.facingDir==louie.c.FACING_LEFT))
				or((louie.tile.previous.leftTouch==false) and(louie.facingDir==louie.c.FACING_RIGHT))then
				louie.ChangeState(louie.c.STATE_NORMAL)
			end
		end

		louie.prevGroundSpeed = louie.groundSpeed
		louie.CollisionUpdate()
	end

	function louie.CollisionUpdate()
		louie.tile.Update()
	end

	function louie.LandOnGround(ycoordinate, angleGround)
		--Update position
		newPosition= CPP.Vec2(0,ycoordinate)

		newPosition= louie.CompPosition:TranslateWorldToLocal(newPosition)

		louie.CompPosition:SetPositionLocalY(newPosition.y)

		--Update variables
		louie.tile.groundTouch=true
		louie.angle=angleGround
	end

	function louie.OnEntityCollision(entityID, packet)
		--Need to get height and collision type
		local leeway=10
		local objectType=packet:GetType()
		local objectName=packet:GetName()
		local otherEntity = CPP.interface:EntityGetInterface(entityID)
		local bounceThreshold = 3

		if louie.input.key[louie.c.K_ACTIVATE] then otherEntity.Activate() end

		local solid = otherEntity.IsSolid()
		local bounce = otherEntity.CanBounce()
		if(solid==true)then
			if(bounce==true)then
				if(louie.yspd >= bounceThreshold)then
					local thisPos = CPP.interface.position:GetWorld(louie.EID)
					local otherPos = CPP.interface.position:GetWorld(entityID)
					if((thisPos.y+louie.c.HEIGHT) <= (otherPos.y + leeway) )then
						louie.yspd = louie.yspd * -.9
						otherEntity.Attack(1)
					end
				end
			end
			if(louie.yspd>=0)then
				local thisPos = CPP.interface.position:GetWorld(louie.EID)
				local otherPos = CPP.interface.position:GetWorld(entityID)
				if((thisPos.y+louie.c.HEIGHT) <= (otherPos.y + leeway) )then
					louie.tile.groundTouch=true
					louie.LandOnGround(otherPos.y-louie.c.HEIGHT, 0)
					CPP.interface.position:SetParent(louie.EID, entityID)

					local vecMove = CPP.interface.position:GetMovement(entityID)
					louie.angle=0

					otherEntity.Land()
				end
			end
		end

		if louie.currentState == louie.c.STATE_SPIN then
			otherEntity.Attack(louie.C.ATTACK.SPIN)
		end
	end

	function louie.GetHat()
		if(louie.health <= 1)then
			louie.health = 2
		end
	end

	function louie.BreakBox(layer, tx, ty)
		--Returns true if box is broken

		tileID = layer:GetTile(tx,ty)
		local isBox = layer:GetTileProperty(tileID, "isBox")
		local boxType1 = 0

		if(isBox == "true")then
			local isBoxHat = layer:GetTileProperty(tileID, "isBoxHat")
			local isSwitch = layer:GetTileProperty(tileID, "switch")

			if(isBoxHat == "true")then
				boxType1 = 1
				louie.GetHat()

			elseif(isSwitch ~= nil)then
				louie.CompScript:BroadcastEvent(tostring(isSwitch))
			end

			--destroy box
			layer:SetTile(tx,ty, 0)
			layer:UpdateRenderArea(CPP.Rect(tx,ty, 1,1))

			--Display box break effect
			local name = ""
			local scriptName = "Effects/boxBreak.lua"
			local scriptProperties = {boxType = boxType1}

			local c = CPP.interface
			local scriptEID = c.entity:New()
			c:GetPositionComponent(scriptEID):SetPositionWorld(CPP.Vec2(tx*16,ty*16))
			c:GetSpriteComponent(scriptEID):SetDepth(louie.depth)
			c.script:CreateEntity(scriptEID, {scriptName}, scriptProperties)

			--Return true, indicating box was broken
			return true
		end

		--Return false, indicating box was NOT broken
		return false
	end

	function louie.OnTileCollision(packet)
	end

	function louie.OnTileDown(packet, newPosition)
		--Update position
		local tx = packet:GetTileX()
		local ty = packet:GetTileY()
		local layer = packet:GetLayer()
		local absoluteCoords=louie.CompPosition:GetPositionWorld()
		local newAngle = packet:GetHMap().angleH
		newPosition= louie.CompPosition:TranslateWorldToLocal(newPosition)
		louie.CompPosition:SetPositionLocalY(newPosition.y)

		--if box can be broken, jump
		if(louie.BreakBox(layer, tx, ty))then
			louie.BoxJump()
		end

		--Update variables
		louie.angle= newAngle
		louie.debug_tcolx=tx
		louie.debug_tcoly=ty
		CPP.interface.position:SetParent(louie.EID, 0)
	end

	function louie.OnTileLeft(packet, newPosition)
		if louie.tile.groundTouch then
			if louie.groundSpeed <= 0 then
				louie.OnTileHorizontal(packet, newPosition)
			end
		else
			if louie.xspd <= 0 then
				louie.OnTileHorizontal(packet, newPosition)
			end
		end
	end
	function louie.OnTileRight(packet, newPosition)
		if louie.tile.groundTouch then
			if louie.groundSpeed >= 0 then
				louie.OnTileHorizontal(packet, newPosition)
			end
		else
			if louie.xspd >= 0 then
				louie.OnTileHorizontal(packet, newPosition)
			end
		end
	end
	function louie.OnTileHorizontal(packet, newPosition)
		local tx = packet:GetTileX()
		local ty = packet:GetTileY()
		local layer = packet:GetLayer()
		if(louie.currentState == louie.c.STATE_ROLL)then
			--if box can be broken, Don't stop momentum
			if(louie.BreakBox(layer, tx, ty))then
				return
			else
				louie.ChangeState(louie.c.STATE_NORMAL)
			end
		end

		newPosition= louie.CompPosition:TranslateWorldToLocal(newPosition)
		louie.CompPosition:SetPositionLocalX(newPosition.x)


		louie.xspd=0 --for when in the air
		louie.groundSpeed=0

	end

	function louie.OnTileUp(packet, newPosition)
		local tx = packet:GetTileX()
		local ty = packet:GetTileY()
		local layer = packet:GetLayer()
		if (louie.yspd<0) then
			louie.BreakBox(layer, tx, ty)
			louie.CompPosition:TranslateWorldToLocal(newPosition)
			louie.CompPosition:SetPositionLocalY(newPosition.y)
			louie.yspd=0
		end
		louie.mainSprite:SetAnimationSpeed(0)
	end

	function louie.TakeDamage(hitpoints)
		louie.xspd = louie.c.KNOCKBACK_SPEED_X * louie.facingDir*-1
		louie.yspd = louie.c.KNOCKBACK_SPEED_Y
		louie.attackLock=true
		louie.LockInput(30)

		louie.health = louie.health-hitpoints
		if (louie.health == 1) then
			local c = CPP.interface

			local pos = louie.CompPosition:GetPositionWorld()
			local name = ""
			local scriptName = "Effects/fallingHat.lua"
			local EID = c.entity:New()
			c:GetPositionComponent(EID):SetPositionWorld(pos)
			c:GetSpriteComponent(EID):SetDepth(louie.depth)
			c.script:CreateEntity(EID, {scriptName}, {direction = louie.facingDir*-1})

			c:PlaySound(louie.SoundFireball, 100)
		end
	end

	function louie.Attacked(damage)
		if louie.currentState == louie.c.STATE_ROLL then--if not rolling
			return false -- not hit
		elseif louie.currentState == louie.c.STATE_SPIN then
			if damage <= 1 then
				return false
			end
		end

		louie.TakeDamage(damage)
		return true --was hit
	end

	louie.EntityInterface = louie.EntityInterface or {}
	local ei = louie.EntityInterface
	ei.IsSolid		= function ()		return true end
	ei.IsPlayer	= function ()		return true end
	ei.GetHealth = function ()			return louie.health end
	ei.Attack		= function (damage) return louie.Attacked(damage) end

	table.insert(louie.InitFunctions, louie.MainInitialize)
	table.insert(louie.UpdateFunctions, louie.MainUpdate)

	return louie
end

return container.NewLouie
