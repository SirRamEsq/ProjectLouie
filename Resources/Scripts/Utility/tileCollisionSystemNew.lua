--DEBUG

local c = {}
c={}

c.cpp = CPP.interface
c.component=nil

--this tile coordinate will be ignored by top and bottom colliders
--if the coordinate is hit by either the left or right c boxes
c.ignoreTileX=-1

c.WIDTH=0
c.HEIGHT=0
c.TILEWIDTH=16
c.TILEHEIGHT=16

--Where BOXs are relative to ground (Down) position
--Should check horizontal boxes first
c.FEET_OFFSET=8

c.footHeightValue=0

c.previous={}
c.previous.tileLeft =false
c.previous.tileRight=false
c.previous.tileUp	=false

c.callbackFunctions={}
c.callbackFunctions.TileUp		=nil
c.callbackFunctions.TileDown	=nil
c.callbackFunctions.TileLeft	=nil
c.callbackFunctions.TileRight	=nil

--Rect shapes will be stored here
c.boxRect = {}
--Actual Collision Boxes will be stored here
c.boxes = {}
--get rid of this
c.boxReverseMap = {}

--primary key to be used for boxRect and boxes
c.boxID = {}
c.boxID.TILE_UP = 1
c.boxID.TILE_DOWN_L = 2
c.boxID.TILE_DOWN_R = 3
c.boxID.TILE_LEFT = 4
c.boxID.TILE_LEFT_SHORT = 5
c.boxID.TILE_RIGHT = 6
c.boxID.TILE_RIGHT_SHORT = 7


c.coordinates={}
c.coordinates.GROUND_R_X_OFFSET =  2
c.coordinates.GROUND_L_X_OFFSET =  -2
c.coordinates.GROUND_Y_OFFSET	=  c.FEET_OFFSET
c.coordinates.GROUND_H_OFFSET	=  1+c.FEET_OFFSET

c.coordinates.RIGHT_X_OFFSET	=  0
c.coordinates.RIGHT_Y_OFFSET	=  4
c.coordinates.RIGHT_W_OFFSET	=  1
c.coordinates.RIGHT_H_OFFSET	=  8

c.coordinates.LEFT_X_OFFSET		=  0
c.coordinates.LEFT_Y_OFFSET		=  4
c.coordinates.LEFT_W_OFFSET		=  -1
c.coordinates.LEFT_H_OFFSET		=  8

c.coordinates.RIGHT_SHORT_Y_OFFSET	=  11
c.coordinates.RIGHT_SHORT_H_OFFSET	=  4

c.coordinates.LEFT_SHORT_Y_OFFSET	=  11
c.coordinates.LEFT_SHORT_H_OFFSET	=  4

c.coordinates.UP_Y_OFFSET		=  0
c.coordinates.UP_H_OFFSET		=  -1
c.coordinates.UP_W_OFFSET		=  2
c.coordinates.UP_X_OFFSET		=  1

c.coordinates.LEFT_ORDER		=  15
c.coordinates.RIGHT_ORDER		=  15
c.coordinates.GROUND_ORDER		=  5
c.coordinates.UP_ORDER			=  10

--Collision Boxes
--Tile Collision Boxes
c.boxTileRight=nil
c.boxTileLeft=nil
c.boxTileUp=nil
c.boxTileDownA=nil
c.boxTileDownB=nil

--Collision state variables
c.frameProperties={}
c.frameProperties.highestHeight=0
c.frameProperties.lowestAngle=0
c.frameProperties.firstCollision=false


function c.AngleToSignedAngle(a)
	if(a>180)then
		a= a - 360
	end
	return a
end

--can replace iface with an errorlogging call back
function c.Init(w, h, eid)
	c.SetWidthHeight(w,h)
	c.EID = eid
	c.component = c.cpp:GetCollisionComponent(eid)

	local coords=c.coordinates
	local comp = c.component
	local boxID = c.boxID
	local boxes = c.boxes

	local order = {}
	order[boxID.TILE_UP] = coords.UP_ORDER
	order[boxID.TILE_DOWN_R] = coords.GROUND_ORDER
	order[boxID.TILE_DOWN_L] = coords.GROUND_ORDER
	order[boxID.TILE_LEFT] = coords.LEFT_ORDER
	order[boxID.TILE_LEFT_SHORT] = coords.LEFT_ORDER
	order[boxID.TILE_RIGHT_SHORT] = coords.RIGHT_ORDER
	order[boxID.TILE_RIGHT] = coords.RIGHT_ORDER

	local callbacks = {}
	callbacks[boxID.TILE_UP] = c.OnTileCollision
	callbacks[boxID.TILE_DOWN_R] = c.OnTileCollision
	callbacks[boxID.TILE_DOWN_L] = c.OnTileCollision
	callbacks[boxID.TILE_LEFT] = c.OnTileCollision
	callbacks[boxID.TILE_LEFT_SHORT] = c.OnTileCollision
	callbacks[boxID.TILE_RIGHT_SHORT] = c.OnTileCollision
	callbacks[boxID.TILE_RIGHT] = c.OnTileCollision

	local boxRects = c.boxRect
	boxRects[boxID.TILE_RIGHT		] =
	CPP.Rect(coords.RIGHT_X_OFFSET,	coords.RIGHT_Y_OFFSET,			coords.RIGHT_W_OFFSET,	coords.RIGHT_H_OFFSET)

	boxRects[boxID.TILE_LEFT		]=
	CPP.Rect(coords.LEFT_X_OFFSET,	coords.LEFT_Y_OFFSET,			coords.LEFT_W_OFFSET,	coords.LEFT_H_OFFSET )

	boxRects[boxID.TILE_RIGHT_SHORT]=
	CPP.Rect(coords.RIGHT_X_OFFSET,	coords.RIGHT_SHORT_Y_OFFSET,	coords.RIGHT_W_OFFSET,	coords.RIGHT_SHORT_H_OFFSET)

	boxRects[boxID.TILE_LEFT_SHORT	]=
	CPP.Rect(coords.LEFT_X_OFFSET,	coords.LEFT_SHORT_Y_OFFSET,		coords.LEFT_W_OFFSET,	coords.LEFT_SHORT_H_OFFSET )

	boxRects[boxID.TILE_UP			]=
	CPP.Rect(coords.UP_X_OFFSET,	coords.UP_Y_OFFSET,				coords.UP_W_OFFSET,		coords.UP_H_OFFSET	 )

	boxRects[boxID.TILE_DOWN_R]=
	CPP.Rect(coords.GROUND_R_X_OFFSET,	coords.GROUND_Y_OFFSET,		0,	coords.GROUND_H_OFFSET)

	boxRects[boxID.TILE_DOWN_L]=
	CPP.Rect(coords.GROUND_L_X_OFFSET,	coords.GROUND_Y_OFFSET,		0,	coords.GROUND_H_OFFSET)

	local solidLayers = c.cpp:GetLayersWithProperty("_SOLID", true)
	local layerCount = solidLayers:size()
	for id, rect in pairs(boxRects)do
		boxes[id] = comp:AddCollisionBox(rect)
		boxes[id]:SetOrder(order[id])
		boxes[id]:CheckForTiles()
		for i=0, layerCount - 1 do
			local layer = solidLayers:at(i)
			boxes[id]:CheckForLayer(layer, callbacks[id])
		end
		c.boxReverseMap[boxes[id]] = id
	end

	boxes[boxID.TILE_RIGHT_SHORT]:Deactivate()
	boxes[boxID.TILE_LEFT_SHORT]:Deactivate()

	c.groundTouch=false
	c.ceilingTouch=false
end

function c.SetWidthHeight(w, h)
	--louie is 18,32
	c.WIDTH=w
	c.HEIGHT=h
	c.coordinates.GROUND_R_X_OFFSET		=  w-2
	c.coordinates.GROUND_L_X_OFFSET		=  2
	c.coordinates.GROUND_Y_OFFSET		=  h-c.FEET_OFFSET
	c.coordinates.GROUND_H_OFFSET		=  1+c.FEET_OFFSET
	c.coordinates.GROUND_ORDER			=  5

	--The left and right c boxes are closer to the top than the bottom
	--this is to allow for covering rougher terrain without the left and right
	--c boxes incorrectly setting off a c event
	--A happy side effect is that the character feet will land on the ledge at a
	--higher y coordinate (lower on the screen) than they would otherwise
	--(when such a c would result in left or right firing instead of feet)

	c.coordinates.RIGHT_X_OFFSET		=  w
	c.coordinates.RIGHT_Y_OFFSET		=  9
	c.coordinates.RIGHT_W_OFFSET		=  1
	c.coordinates.RIGHT_H_OFFSET		=  h-14
	c.coordinates.RIGHT_ORDER			=  15

	c.coordinates.LEFT_X_OFFSET			=  0
	c.coordinates.LEFT_Y_OFFSET			=  9
	c.coordinates.LEFT_W_OFFSET			=  -1
	c.coordinates.LEFT_H_OFFSET			=  h-14
	c.coordinates.LEFT_ORDER			=  15

	c.coordinates.RIGHT_SHORT_Y_OFFSET	=  16
	c.coordinates.RIGHT_SHORT_H_OFFSET	=  2

	c.coordinates.LEFT_SHORT_Y_OFFSET	=  16
	c.coordinates.LEFT_SHORT_H_OFFSET	=  2

	c.coordinates.UP_Y_OFFSET			=  8
	c.coordinates.UP_H_OFFSET			=  1
	c.coordinates.UP_W_OFFSET			=  math.floor(w/2)
	c.coordinates.UP_X_OFFSET			=  math.floor(w/4)
	c.coordinates.UP_ORDER				=  10
end

function c.GetHeightMapValue(absoluteX, tileCollisionPacket)
	local MAX_HEIGHT = 15
	local MIN_HEIGHT = 0

	if(tileCollisionPacket:GetLayer():UsesHMaps() == false) then return MAX_HEIGHT end

	local box_value = 0
	local boxid=tileCollisionPacket:GetBox():GetID()
	local hmap=tileCollisionPacket:GetHmap()
	local HMAP_index_value= 0
	local tx=tileCollisionPacket:GetTileX()

	--First, figure out the x-coordinate of the heightmap value (height map index value)
	if(boxid==c.boxes[c.boxID.TILE_DOWN_R]:GetID()) then
		box_value = c.coordinates.GROUND_R_X_OFFSET
	elseif(boxid==c.boxes[c.boxID.TILE_DOWN_L]:GetID()) then
		box_value = c.coordinates.GROUND_L_X_OFFSET
	end

	--Get the world x position of the c box
	box_value= box_value + absoluteX
	HMAP_index_value= box_value - (tx*c.TILEWIDTH)

	--Got the heightmap index value, now actually get the height value and set the proper y-value
	if((HMAP_index_value>MAX_HEIGHT)or(HMAP_index_value<MIN_HEIGHT))then
		c.cpp:LogError(c.EID, "Uh-Oh, index '" .. HMAP_index_value .. "' is out of bounds with boxValue '" .. box_value .. "' and tx '" .. tx .. "'")
		c.cpp:LogError(c.EID, tostring(HMAP_index_value))
		return
	end

	return hmap:GetHeightMapH( HMAP_index_value )
end

function c.UseShortBoxes()
	local boxID = c.boxID
	local boxes = c.boxes
	boxes[boxID.TILE_RIGHT_SHORT]:Activate()
	boxes[boxID.TILE_LEFT_SHORT]:Activate()
	boxes[boxID.TILE_RIGHT]:Deactivate()
	boxes[boxID.TILE_LEFT]:Deactivate()
end

function c.UseNormalBoxes()
	local boxID = c.boxID
	local boxes = c.boxes
	boxes[boxID.TILE_RIGHT_SHORT]:Deactivate()
	boxes[boxID.TILE_LEFT_SHORT]:Deactivate()
	boxes[boxID.TILE_RIGHT]:Activate()
	boxes[boxID.TILE_LEFT]:Activate()
end

function c.Update(xspd, yspd)
	if(c.groundTouch==true)then
		c.footHeightValue=math.floor(yspd+0.5+c.FEET_OFFSET+math.abs(xspd))+2
	else
		c.footHeightValue=math.floor(yspd + 0.5 + c.FEET_OFFSET)+1
	end

	local boxID = c.boxID
	local boxShapes = c.boxRect
	boxShapes[boxID.TILE_DOWN_R].h	= c.footHeightValue
	boxShapes[boxID.TILE_DOWN_L].h	= c.footHeightValue
	boxShapes[boxID.TILE_LEFT].w	= math.floor(xspd - 0.5)
	boxShapes[boxID.TILE_RIGHT].w	= math.floor(xspd + 0.5)
	boxShapes[boxID.TILE_LEFT_SHORT].w	= math.floor(xspd - 0.5)
	boxShapes[boxID.TILE_RIGHT_SHORT].w		= math.floor(xspd + 0.5)
	boxShapes[boxID.TILE_UP].h		= math.floor(yspd - 2.5)

	for k,v in pairs(boxID)do
		c.boxes[v]:SetShape( boxShapes[v])
	end

	c.previous.tileLeft =false
	c.previous.tileRight=false
	c.previous.tileUp		=false
	c.ignoreTileX=-1
	c.prevGroundTouch=c.groundTouch
	c.groundTouch=false
	c.rightWall=false
	c.leftWall=false
	c.ceilingTouch=false
	c.frameProperties.firstCollision=false
	c.xspd = xspd
	c.yspd = yspd
end

function c.OnTileCollision(packet)
	local box=packet:GetBox()
	local boxid = box:GetID()

	local tx=packet:GetTileX()
	local ty=packet:GetTileY()
	local pos = c.cpp:GetPositionComponent(c.EID):GetPositionWorld()
	local xval = pos.x
	local yval = pos.y

	local layer=packet:GetLayer()
	local usesHMaps=layer:UsesHMaps()
	local hmap=packet:GetHmap()

	local hspd = c.xspd
	local vspd = c.yspd

	local newPosition

	--Commonly used variables
	local HMAPheight=0
	local frameheight=ty * c.TILEHEIGHT

	if(c.frameProperties.firstCollision==false)then
		c.frameProperties.highestHeight=frameheight + 1000
		c.frameProperties.lowestAngle=360
		c.frameProperties.firstCollision=true
	end

	--============================--
	--If Ground Collision Occurred--
	--============================--
	if ( ((boxid==c.boxes[c.boxID.TILE_DOWN_R]:GetID()) or (boxid==c.boxes[c.boxID.TILE_DOWN_L]:GetID()))
		and(tx~=c.ignoreTileX)
		) then

		local thisAngle=hmap.angleH
		local thisAngleSigned= c.AngleToSignedAngle(thisAngle)
		local maximumFootY=c.footHeightValue + yval + c.coordinates.GROUND_Y_OFFSET
		local HMAPheight= c.GetHeightMapValue(xval, packet)

		--Don't register a c if there isn't any height value
		if (HMAPheight==0 or HMAPheight==nil) then return end
		--This line of code stops you from clipping through objects you're riding on to land on the tile beneath you
		if ((ty*16)-HMAPheight+16)>maximumFootY then return end

		frameheight = frameheight - HMAPheight
		if(frameheight>c.frameProperties.highestHeight)then
			return --Only stand on the highest height value found

		elseif(c.frameProperties.highestHeight==frameheight)then
			if( (math.abs(c.frameProperties.lowestAngle)<=math.abs(thisAngleSigned)) )then
				return --if the heights are the same, only stand on the lowest angle
			end
		end

		--Update position
		newPosition=CPP.Coord2df(xval, ( (ty+1) *16 ) - c.HEIGHT - HMAPheight)

		--Update variables
		c.frameProperties.lowestAngle=math.abs(thisAngleSigned)
		c.frameProperties.highestHeight=frameheight
		c.groundTouch=true

		c.callbackFunctions.TileDown(newPosition, thisAngle, layer, tx, ty)

		--===========================--
		--If Right Collision Occurred--
		--===========================--
	elseif  ((boxid==c.boxes[c.boxID.TILE_RIGHT_SHORT]:GetID()) or (boxid==c.boxes[c.boxID.TILE_RIGHT]:GetID()) ) then
		if(usesHMaps)then
			return
		end
		c.rightWall = true
		if((hspd>=0) or ((c.groundTouch==false) and (hspd==0)))  then
			newPosition=CPP.Coord2df( (tx*c.TILEWIDTH)-c.WIDTH, yval)

			c.previous.tileRight=true
			--The top c box won't try to collide with this tile for the rest of the frame
			--It's impossible, because since you just collided with the x-coord to your right and were pushed back, you
			--can't possibly also have it above you
			c.ignoreTileX=tx

			c.callbackFunctions.TileRight(newPosition, layer, tx, ty)
		end

		--==========================--
		--If Left Collision Occurred--
		--==========================--
	elseif  ((boxid==c.boxes[c.boxID.TILE_LEFT_SHORT]:GetID()) or (boxid==c.boxes[c.boxID.TILE_LEFT]:GetID()) ) then
		if(usesHMaps)then
			return
		end
		c.leftWall = true
		if((hspd<=0) or ((c.groundTouch==false) and (hspd==0))) then
			--Subtract one because (tx+1) pushes one pixel past the actual tile colided with
			newPosition=CPP.Coord2df(((tx+1)*c.TILEWIDTH)-1, yval)

			c.previous.tileLeft=true
			--The top c box won't try to collide with this tile for the rest of the frame
			--It's impossible, because since you just collided with the x-coord to your left and were pushed back, you
			--can't possibly also have it above you
			c.ignoreTileX=tx
			c.callbackFunctions.TileLeft(newPosition, layer, tx, ty)
		end

		--=========================--
		--If Top Collision Occurred--
		--=========================--
	elseif ((boxid==c.boxes[c.boxID.TILE_UP]:GetID()) and(tx~=c.ignoreTileX))then
		--Subtract one because (ty+1) pushes one pixel past the actual tile colided with
		c.ceilingTouch=true
		if(usesHMaps)then
			return
		end
		newPosition=CPP.Coord2df(xval, ((ty+1)*c.TILEHEIGHT)-1)

		c.previous.tileUp		=true

		c.callbackFunctions.TileUp(newPosition, layer, tx, ty)
	end
end


--return container
return c
