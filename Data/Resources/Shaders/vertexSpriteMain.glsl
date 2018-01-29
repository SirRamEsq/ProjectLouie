#version 300 es
precision highp float;

layout (location = 0) in vec2 position; 	//vertex data
layout (location = 1) in vec2 texture; 		//texture
layout (location = 3) in vec4 color;		//color
layout (location = 4) in vec4 scalingRotation;  //ScalingRotation
layout (location = 5) in vec2 worldPos;		//Translation

out vec2 texture_coordinates;
out vec4 colorValue;

layout(std140) uniform CameraData
{
//Only camera translation is needed
//Camera scaling and rotation will take place when the camera applies it's buffer texutre (that it renderes the screen to) to a viewport
    mat4 viewMatrix;
    mat4 projMatrix;
    mat4 projMatrixInverse;
};

const float ONE_DEG_IN_RAD = ((2.0 * 3.14) / 360.0);   // 0.017444444

uniform float depth;

void main() {
	//Fragment shader variables
	texture_coordinates	= texture;
	colorValue 		= color;
	
	//Calculate position
	float rad = scalingRotation.z * ONE_DEG_IN_RAD;
	float scaleX = scalingRotation.x;
	float scaleY = scalingRotation.y;

	mat4 scaling = mat4(
	  	vec4(scaleX, 0.0,    0.0,   0.0),           //first column
		vec4(0.0,    scaleY, 0.0,   0.0),           //second column
	  	vec4(0.0,    0.0,    1.0,   0.0),           //third column
	  	vec4(0.0,    0.0,    0.0,   1.0)            //fourth column
	);

	mat4 translate = mat4(
	  	vec4(1.0, 	0.0, 	0.0,   0.0),     	//first column
		vec4(0.0, 	1.0, 	0.0,   0.0),   		//second column
	  	vec4(0.0, 	0.0, 	1.0,   0.0),   		//third column
	  	vec4(worldPos.x, worldPos.y, 	0.0,   1.0)     	//fourth column
	);

	mat4 rotationZ = mat4(
	  	vec4(cos(rad),  sin(rad), 0.0, 	0.0),           //first column
		vec4(-sin(rad), cos(rad), 0.0, 	0.0),           //second column
	  	vec4(0.0,       0.0,      1.0, 	0.0),           //third column
	  	vec4(0.0, 	0.0, 	  0.0, 	1.0)            //fourth column
	);	

	vec4 temp = vec4(position.x, position.y, depth, 1.0);
	vec4 worldSpace =  (translate * rotationZ * scaling) * temp;

	gl_Position = projMatrix * viewMatrix * worldSpace;
}
