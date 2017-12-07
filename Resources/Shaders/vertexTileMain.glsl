#version 300 es

layout (location = 0) in vec2 position; 	//vertex data
layout (location = 1) in vec2 texture; 		//x,y, position (in tileCoords) of first frame of tile on texture, z,w are tex width and height
//layout (location = 2) in vec2 animation;	//animation data (x = animation sped (float), y = max frames (int) )

out vec2 texture_coordinates;
out vec4 colorValue;

layout(std140) uniform CameraData{
    mat4 viewMatrix;
    mat4 projMatrix;
    mat4 projMatrixInverse;
};

layout(std140) uniform ProgramData
{
//time.x = current time
    vec4 time;
};

uniform vec4 layerColor;
uniform float depth;
uniform vec2 textureDimensions;

void main() {
	//highp int timeValue = int(animation.x * time.x);
	//highp int maxFrame = int(animation.y);

	//Fragment shader variables
	//vec2 texTemp;
	//texTemp.x = texture.x +  ( float(timeValue % maxFrame) * (16.0 / texture.z) );
	//texTemp.y = texture.y;

	texture_coordinates = texture;

	colorValue 		= layerColor;
	
	vec4 temp;
	temp.x = position.x;
	temp.y = position.y;
	temp.z = depth;
	temp.w = 1.0;

	gl_Position = projMatrix * viewMatrix * temp;
}
