<?xml version="1.0" encoding="UTF-8"?>
<tileset name="items" tilewidth="16" tileheight="16" tilecount="256" columns="16">
 <image source="tiledImages/items.png" trans="ff00ff" width="256" height="256"/>
 <tile id="2">
  <properties>
   <property name="coinValue" type="int" value="1"/>
  </properties>
  <animation>
   <frame tileid="2" duration="100"/>
   <frame tileid="3" duration="100"/>
   <frame tileid="4" duration="100"/>
   <frame tileid="5" duration="100"/>
   <frame tileid="6" duration="100"/>
   <frame tileid="7" duration="100"/>
  </animation>
 </tile>
 <tile id="50">
  <properties>
   <property name="bounce" type="int" value="8"/>
  </properties>
 </tile>
 <tile id="80">
  <properties>
   <property name="isBox" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="81">
  <properties>
   <property name="bounce" type="int" value="8"/>
   <property name="isBox" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="82">
  <properties>
   <property name="isBox" type="bool" value="true"/>
   <property name="switch" type="int" value="0"/>
  </properties>
 </tile>
 <tile id="83">
  <properties>
   <property name="isBox" type="bool" value="true"/>
   <property name="isBoxHat" type="bool" value="true"/>
  </properties>
 </tile>
</tileset>
