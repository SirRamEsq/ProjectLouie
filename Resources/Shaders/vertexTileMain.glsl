#version 300 es

layout (location = 0) in vec2 position; 	//vertex data
layout (location = 1) in vec2 texture; 	//x,y, position (in tileCoords) of first frame of tile on texture
layout (location = 2) in vec4 color;		//color
layout (location = 3) in vec2 animation;	//animation data (x = frames to increment animation, y = max frames)

out vec2 texture_coordinates;
out vec4 colorValue;

layout(std140) uniform CameraData
{
//Only camera translation is needed
//Camera scaling and rotation will take place when the camera applies it's buffer texutre (that it renderes the screen to) to a viewport
    vec4 cameraTranslation;
    mat4 projMatrix;
};

layout(std140) uniform ProgramData
{
//time.x = current time
    vec4 time;
};

void main() {
	//Fragment shader variables
	texture_coordinates 	= texture;// + ( ( (animationTime * maxAnimation) % time) * (textureWidth/16) );
	colorValue 		= color;
	
	vec2 temp;
	temp.x = position.x - cameraTranslation.x;
	temp.y = position.y - cameraTranslation.y;

	gl_Position = projMatrix * (vec4(temp, 1.0, 1.0));
}