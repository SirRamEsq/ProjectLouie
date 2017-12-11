#version 300 es

precision highp float;
#define MAX_LIGHTS 32

struct PointLight{
	vec4 worldPos;
	vec4 color;
	vec4 extra;
	//extra.x; radius
	//extra.y; flicker
};

in vec2 textureCoordinates;

uniform sampler2D diffuseTex;
uniform sampler2D depthTex;

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

out vec4 frag_color;

/*

vec3 CalcPointLight(in PointLight light, in vec3 fragWorld, in vec4 fragDepth){
	// Attenuation
	float distance = length(light.worldPos.xyz - fragWorld);
	//between 0.0 and 1.0
	float attenuation = max(0.0, (light.extra.x - distance) / light.extra.x);

	vec3 lightColor = light.color.xyz * attenuation;

	return (lightColor);
}
*/

void main(){
	// Properties
	vec4 diffuseTexel	= texture (diffuseTex, textureCoordinates);
	//vec4 depthTexel		= texture (depthTex, textureCoordinates);
	//vec4 fragView = projMatrixInverse * gl_FragCoord;
	//vec4 fragWorld = inverse(viewMatrix) * fragView;

	// Phase 1: Ambient lighting
	vec3 lightColor = AMBIENT_COLOR;

	// Phase 2: Point lights
	//for (int i = 0; i < activeLights; i++){
		//lightColor += CalcPointLight(pointLights[i],fragWorld.xyz, depthTexel);
	//}


	// Phase 3: final color
	vec3 result = lightColor * diffuseTexel.xyz;
	result = clamp(result, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));

	frag_color = vec4(result, 1.0);
}
