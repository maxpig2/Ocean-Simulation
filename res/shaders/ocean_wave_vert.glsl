#version 330 core

// uniform data
uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;
uniform vec3 uColor;
uniform float uTime;
uniform float uAmplitude;
uniform float uWaveLength;
uniform float uPeriod;

// mesh data
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3) in vec3 aTangent;

// model data (this must match the input of the vertex shader)
out VertexData {
	vec3 position;
	vec3 normal;
	vec2 textureCoord;
	mat3 tbn;
	
} v_out;

void main() {
	// transform vertex data to viewspace
	v_out.position = (uModelViewMatrix * vec4(aPosition, 1)).xyz;
	v_out.normal = normalize((uModelViewMatrix * vec4(aNormal, 0)).xyz);
	v_out.textureCoord = aTexCoord;

	vec3 newPosition;
	
	float surfaceElevation = 0;				//	n		The vertical displacement from the mean water level of the oceanic surface at a given point and time. 
	float amplitude = uAmplitude; 			// 	a		The maximum surface elevation due to this wave. 
	float waveHeight = amplitude * 2.0;		// 	H		The vertical distance between a trough and an adjacent crest.
	float waveLength = uWaveLength;			// 	Lambda 	The distance between 2 successive crests.
	float period = uPeriod;					// 	T 		The time interval between the passage of successive crests through a fixed point. 
	float frequency = 1.0 / period;			//	f		The number of of crests that pass a fixed point in 1 second. 
	float waveSpeed = waveLength / period;	// 	c 		The	speed of wave crests or troughs. 
	float waterDepth = 100;					//	d 		The vertical distance between the floor and the mean water level.

	float angularVelocity = 2.0 * 3.1415 * frequency;	// 	w 	The angular velocity/angular frequency
	float waveNumber = (2.0 * 3.1415) / waveLength;		// 	k	The number of waves. 


	float x = 0;
	float y = 0;
	float z = 0;

	//Equation 1
	/*
	float z = aPosition.z - amplitude * cos( (waveNumber * aPosition.x) - (angularVelocity * uTime) );
	newPosition = aPosition + vec3(0,z,0);
	*/

	//Equation 2
	//z = aPosition.z - amplitude * cos( (waveNumber * aPosition.x) - (angularVelocity * uTime) );
	//float x = aPosition.x + amplitude * sin( (waveNumber * aPosition.x) - (angularVelocity * uTime) );

	//Airy Wave Equation
	y = amplitude * cos( 2 * 3.1415 * ((aPosition.x / waveLength) - (uTime/period)));
	//x = amplitude * sin( 2 * 3.1415 * ((aPosition.x / waveLength) + (uTime/period)));

	float spectrumPeakFrequency; 	// Wp	The frequency of the peak of the spectrum.
	float windSpeed = 10.0;
	float gravity = 9.81;			//	g	Gravity

	spectrumPeakFrequency = (0.855 * gravity) / windSpeed;
	float parametricWaveSpectrum = (0.0081 * gravity * gravity) /  pow(angularVelocity, 5); 
	float spectrumParametricMean = pow(parametricWaveSpectrum, ( (-5.0/4.0) * pow( (spectrumPeakFrequency/angularVelocity), 4) ));







	newPosition = aPosition + vec3(x,y,z);
	
	// set the screenspace position (needed for converting to fragment data)
	gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(newPosition, 1);
}