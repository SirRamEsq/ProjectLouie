#version 300 es

layout (location = 0) in vec2 position; 	//vertex data
layout (location = 1) in vec2 texture; 		//texture
layout (location = 3) in vec4 color;		//color

out vec2 texture_coordinates;
out vec4 colorValue;

layout(std140) uniform CameraData{
    mat4 viewMatrix;
    mat4 projMatrix;
    mat4 projMatrixInverse;
};

uniform float depth;

void main() {
	//Fragment shader variables
	texture_coordinates= texture;
	colorValue 		= color;
	
	vec4 temp;
	temp.x = position.x;
	temp.y = position.y;
	temp.z = depth;
	temp.w = 1.0;

	gl_Position = projMatrix * viewMatrix * temp;
}
