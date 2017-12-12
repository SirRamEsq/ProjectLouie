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
	vec4 vars;
	//vars.x = time
	//vars.y = ?
	//vars.z = resolution.x
	//vars.w = resolution.y
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

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 CalcPointLight(in PointLight light, in vec3 fragWorld, in vec4 fragDepth){
	// Attenuation
	float time = vars.x;
	float distance = length(light.worldPos.xy - fragWorld.xy);
	float flicker = rand(fragWorld.xy * vec2(time/fragWorld.y,time/fragWorld.x));

	//between 0.0 and 1.0
	float attenuation = max(0.0, (light.extra.x - distance) / light.extra.x);

	//if(distance < 100.0){
		//return vec3(30.0,30.0,30.0);
	//}

	vec3 lightColor = (light.color.xyz * attenuation) - (flicker * light.extra.y);
	lightColor = max(vec3(0.0, 0.0, 0.0), lightColor);

	return lightColor;
	//return vec3(0.1,0.1,0.1);
}

void main(){
	// Properties
	vec2 resolution = vars.zw;
	vec4 diffuseTexel	= texture (diffuseTex, textureCoordinates);
	vec4 depthTexel		= texture (depthTex, textureCoordinates);
	vec4 fragCoord = gl_FragCoord;
	fragCoord.y = resolution.y - fragCoord.y;
	vec4 fragWorld = inverse(viewMatrix) * fragCoord;

	// Phase 1: Ambient lighting
	vec3 lightColor = AMBIENT_COLOR;

	// Phase 2: Point lights
	for (int i = 0; i < activeLights; i++){
		lightColor += CalcPointLight(pointLights[i],fragWorld.xyz, depthTexel);
	}


	// Phase 3: final color
	vec3 result = lightColor * diffuseTexel.xyz;
	result = clamp(result, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));

	frag_color = vec4(result, 1.0);
}
