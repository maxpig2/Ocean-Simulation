#version 330 core

// uniform data
uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;
uniform vec3 uColor;
uniform float uTime;
uniform float uAmplitude;
uniform float uWaveLength;
uniform float uPeriod;
uniform vec2 uWindDirection;
uniform float uGravity;
uniform float uWaveSeed;
uniform int uWaveNumber;
uniform int uOceanFetch;
uniform float uWindSpeed;
uniform float uChoppiness;
uniform float uOceanSpeed;
uniform float uOceanBasePos;
uniform vec3 uOceanLightPos;
uniform vec3 uCamPos;

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
	float heightPos;
	vec3 wavePos;
} v_out;

vec3 waves(int iterations, vec3 position);

vec3 tangent = vec3(0,0,0);
vec3 binormal = vec3(0,0,0);


vec3 calcNormal(vec3 currentWaves) {
	vec3 normal = currentWaves;
	//normal
	const float EPSILON = 0.001; 
	vec3 tangent = waves(10, vec3(aPosition.x+EPSILON, aPosition.y,aPosition.z)) - normal;
	vec3 binormal = waves(10, vec3(aPosition.x, aPosition.y,aPosition.z+EPSILON)) - normal;
	//normal.x = tangent.x - normal.x + 10;
	//normal.z = binormal.z - normal.z + 10;
	//normal.y = EPSILON;
	//normal = -normalize(normal);
	//tangent -= normal.y;
	//binormal -= normal.y;
	normal = normalize(cross(binormal,tangent));
	return normal;
}








void main() {
	// transform vertex data to viewspace
	
	
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

	//Vertex Displacement Positions
	float x = 0;
	float y = 0;
	float z = 0;



	float spectrumPeakFrequency; 	// Wp	The frequency of the peak of the spectrum.
	float windSpeed = 10.0;
	float gravity = 9.81;			//	g	Gravity

	spectrumPeakFrequency = (0.855 * gravity) / windSpeed;
	float parametricWaveSpectrum = (0.0081 * gravity * gravity) /  pow(angularVelocity, 5); 
	float spectrumParametricMean = pow(parametricWaveSpectrum, ( (-5.0/4.0) * pow( (spectrumPeakFrequency/angularVelocity),4)));

	vec2 windDirection = normalize(uWindDirection);
	
	float k = 2 * (3.1415/waveLength);
	float c = sqrt(waveSpeed/k);
	float f = k * (dot(windDirection, aPosition.xz) - c * uTime);

	x = aPosition.x + windDirection.x * (amplitude * cos(f));
	y = amplitude * sin (f);
	z = aPosition.z + windDirection.y * (amplitude * cos(f));
	vec3 gerstnerWave = vec3(0,0,0);
	

	gerstnerWave = waves(uWaveNumber, aPosition);
	

	vec3 normal = vec3(1,1,1);//calcNormal(gerstnerWave);

	v_out.normal = normalize((uModelViewMatrix * vec4(normal, 0)).xyz);

	newPosition = aPosition + gerstnerWave;

	v_out.wavePos = aPosition;
	v_out.heightPos = newPosition.y;
	v_out.position = (uModelViewMatrix * vec4(newPosition, 1)).xyz;
	// set the screenspace position (needed for converting to fragment data)
	gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(newPosition, 1);
}





	/*
		
	*/


	//randomAmp = 1;

	/*
		int i  = 1;
		gerstnerWave += wave(0.4,2.7 + i,0.5,normalize(vec2(0.5 + i,1)));
		gerstnerWave += wave(1.5,1.5 + i,1.3 + i, normalize(vec2(0.3 + i,0.5)));
		gerstnerWave += wave(1,3.7,3,normalize(vec2(.9,.1 + i)));
		gerstnerWave += wave(0.6,1.3,0.7 +i,normalize(vec2(1.5+i,1 +i)));
		gerstnerWave += wave(0.1,1.3 + i,0.01, normalize(vec2(1+i,1)));
		//gerstnerWave += wave(rand(vec2(aPosition.x,aPosition.y) * 2), i + 2, i /2, vec2(rand(vec2(i,i))));
		//gerstnerWave += wave(rand(vec2(0,i)), i + 2, i /2, vec2(rand(vec2(i+1,i))));
	//	gerstnerWave += wave(rand(vec2(aPosition.y,0)), i + 2, i /2, vec2(rand(vec2(i,i+1))));
	*/

		//Equation 1
	/*
	float z = aPosition.z - amplitude * cos( (waveNumber * aPosition.x) - (angularVelocity * uTime) );
	newPosition = aPosition + vec3(0,z,0);
	*/

	//Equation 2
	//z = aPosition.z - amplitude * cos( (waveNumber * aPosition.x) - (angularVelocity * uTime) );
	//float x = aPosition.x + amplitude * sin( (waveNumber * aPosition.x) - (angularVelocity * uTime) );

	//Airy Wave Equation
//	y = amplitude * cos( 2 * 3.1415 * ((aPosition.x / waveLength) - (uTime/period)));
	//x = amplitude * sin( 2 * 3.1415 * ((aPosition.x / waveLength) + (uTime/period)));



		/*
		gerstnerWave += wave(JONSWAP(w+i, 4.2 + (i*2.0)+(uTime), 0.47+(i/10)),3.4 + i,0.01,normalize(vec2(1+i,1)),position, i*2);
		gerstnerWave += wave(JONSWAP(w+1.2 + rand(vec2(i,i*3)), 3.2 + (i)+(uTime), 1.0+(i/10)),3.4 + i,0.01,normalize(vec2(i+0.1,1)),position, i*i);
		gerstnerWave += wave(JONSWAP(w+.4, 3.2 + (i), 0.2+(i/10)),3.4 + i,0.01,normalize(vec2(0,0.1+i)),position, i*4);
	
		gerstnerWave += wave(6,3.4 + i,0.01,normalize(vec2(1,1)),position, i);
		gerstnerWave += wave(3,3.8 + i,0.1,normalize(vec2( i,1)),position, i*2);
		gerstnerWave += wave(10,2.4 + i,0.001,normalize(vec2(1 +3,1)),position, i*3);
		gerstnerWave += wave(2,1.7 + i,1,normalize(vec2(0,0.01+i)),position, i);
		*/