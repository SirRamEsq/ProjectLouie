#version 300 es

struct PointLight{
	vec4 worldPos;
	vec4 color;
	vec4 extra;
	//extra.x; radius
	//extra.y; flicker
};

layout(location = 0) in vec2 vert;
layout(location = 1) in vec2 vertTexCoord;

#define MAX_LIGHTS 32

uniform vec3 AMBIENT_COLOR;

layout(std140) uniform ProgramData{
	vec4 time;
};

layout(std140) uniform CameraData{
	mat4 viewMatrix;
	mat4 projMatrix;
	mat4 projMatrixInverse;
};

layout(std140) uniform LightData{
	PointLight pointLights[MAX_LIGHTS];
	int activeLights;
};

out vec2 textureCoordinates;

void main(){
	textureCoordinates = vertTexCoord;
	gl_Position = vec4(vert, 1.0, 1.0);
}
