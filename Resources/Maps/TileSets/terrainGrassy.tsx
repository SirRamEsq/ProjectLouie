<?xml version="1.0" encoding="UTF-8"?>
<tileset name="terrainGrassy" tilewidth="16" tileheight="16" tilecount="256" columns="16">
 <image source="tiledImages/terrainGrassy.png" trans="ff00ff" width="256" height="256"/>
 <tile id="160">
  <properties>
   <property name="ANIMATION" value="Water"/>
   <property name="SPRITE" value="tileAnimations/SpriteGrassTerrain.xml"/>
  </properties>
  <animation>
   <frame tileid="160" duration="100"/>
   <frame tileid="161" duration="100"/>
   <frame tileid="162" duration="100"/>
   <frame tileid="163" duration="100"/>
  </animation>
 </tile>
</tileset>
