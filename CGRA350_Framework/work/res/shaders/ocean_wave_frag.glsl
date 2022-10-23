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

// viewspace data (this must match the output of the fragment shader)
in VertexData {
	vec3 position;
	vec3 normal;
	vec2 textureCoord;
	mat3 tbn;
	float heightPos;
	vec3 wavePos;
} f_in;

// framebuffer output
out vec4 fb_color;

vec3 waves(int iterations, vec3 position);


vec3 calcNormal(vec3 position) {
	vec3 normal = waves(uWaveNumber,position);
	//normal
	const float EPSILON = 0.001; 
	vec3 tangent = waves(uWaveNumber, vec3(position.x+EPSILON, position.y,position.z)) - normal;
	vec3 binormal = waves(uWaveNumber, vec3(position.x, position.y,position.z+EPSILON)) - normal;

	normal.y = waves(uWaveNumber,position).y;
	normal.x = waves(uWaveNumber, vec3(position.x+EPSILON, position.y,position.z)).y - normal.y;
	normal.z = waves(uWaveNumber, vec3(position.x, position.y,position.z+EPSILON)).y - normal.y;
	normal.y = EPSILON;
	//normal = normalize(normal);

	normal = normalize(cross(binormal,tangent));

	

	return -normal;
}


void main() {
	vec3 eye = normalize(-f_in.position);
//	eye = normalize(-f_in.position);
	// eye = normalize(uCamPos);
	//eye = -normalize(vec3(uOceanLightPos.x,uOceanLightPos.y,-uOceanLightPos.z));

	vec3 light = vec3(0,0.5,1);
	//if(uOceanLightPos.z < 6) {
	light = normalize(vec3(uOceanLightPos.x, uOceanLightPos.y, -uOceanLightPos.z));
	//light = glm::lookAt(eye,uOceanLightPos,vec3(0,1,0));
	///} else {
	//	light = -normalize(vec3(uOceanLightPos.x, uOceanLightPos.y, uOceanLightPos.z));
	//}
//    light = normalize(vec3(uOceanLightPos.x, -uOceanLightPos.z, -uOceanLightPos.y));
	//light = vec3(uOceanLightPos.x,uOceanLightPos.y,-uOceanLightPos.z);
	
	float PI = 3.1415;
	//Colours
	vec3 objectColour = uColor;
	vec3 specularColour = vec3(1,1,1);
	vec3 lightColour = vec3(0.25,0.15,0.05);

	//lightColour = vec3(1);

	//vec3 N = normalize(); //Unit surface normal
	vec3 N = normalize(calcNormal(f_in.wavePos));

	vec3 V = eye; //Unit vector in direction of the viewer
	vec3 L = normalize(-light); //Unit vector in the direction of a light
	vec3 H = normalize(V+L); //Unit Angular Bisector of V and L

	float G = min(1,min(((2*dot(N,H)*dot(N,V))/dot(V,H)),((2*dot(N,H)*dot(N,L))/dot(V,H)))); //Geometrical Attenuation Factor

	float a = acos(dot(N,H)); //Angle between N and H
	float m = .4; //Root mean square slope of facets
	//m = uOceanLightPos.y/2;
	float D = (exp((-pow(tan(a),2)/ pow(m,2)))) / (PI*pow(m,2)*pow(cos(a),4)) ; //Facet slope distribution function

	float c = dot(V,H); //*
	float n = 0.1;//indexOfRefraction 
	float F0 = pow(n-1,2)/pow(n+1,2);
	float F = F0 + (1 -F0) * pow(1.0 - c, 5);//Reflectance of a perfectly smooth surface

	float Rs = (F/PI) * ((D*G)/(dot(N,L)*dot(N,V))); //Specular Bidirectional Reflectance
	Rs = (D*G*F)/(4*dot(N,L)*dot(N,V));

	float diffuse = max(dot(N,L),0.0);
	float k = 0.0; // Extinction Coefficient

	float specularity  = 0.0;
	float shininess = 30;
	
	if (diffuse > 0.0){ 
	vec3 Haa = normalize(L+V);
	float specularAngle = max(dot(Haa,N),0);
	specularity = pow(specularAngle,shininess);
	}

	vec3 baseCol = uColor /10;
	float heightColRamp = 0;//f_in.heightPos - uOceanBasePos;
    
    float inten = min(0.3+uOceanLightPos.y, 0.9);
	inten = 0;
	//inten = 0;
    vec3 sunset = vec3(0.65, 0.30, 0.25);
    vec3 daylight = vec3(0.15, 0.47, 0.72);
    
    vec3 col = mix(sunset, daylight, uOceanLightPos.y);
    
	vec3 fragColour = ((diffuse + inten + 0.1 + (heightColRamp/10)) * objectColour) +  (lightColour * specularColour * (k + Rs * (1.0 - k))) + (diffuse * col) ;
	//fragColour = eye;

	/*
	float PI = 3.1415;
	// calculate lighting (hack)
	vec3 eye = normalize(-f_in.position);
	vec3 light = vec3(0.5,0.5,-1);
	//Variables
	vec3 L = normalize(-light); //Light Source Direction
	vec3 V = eye; //Viewing Direction
	//vec3 N = normalize(f_in.normal); //Unit surface normal
	vec3 N = calcNormal(f_in.wavePos);


	//Calculate S and T
	float s = dot(L,V) - (dot(N,L)*dot(N,V));
	float t = 0.0;
	if (s <= 0) {
		t = 1.0;
	} else {
		t = max(dot(N,L),dot(N,V));
	}
	
	float sigma = 0.1f;
	float sigmaSquared = sigma*sigma;
	float p = 3.0;
	float A = (1/PI)* ( 1 - 0.5 * (sigmaSquared/(sigmaSquared+0.33) + (0.17*p) * (sigmaSquared/(sigmaSquared+0.13))  )       );
	float B = (1/PI) * (0.45 * (sigmaSquared / (sigmaSquared + 0.09)));

	//"Improved" Oren Nayar Implementation
	A = 1/(PI + ((PI/2.0) - (2.0/3.0)) * sigma);
	B = sigma/(PI + ((PI/2.0) - (2.0/3.0)) * sigma);

	float diffuse = (p * dot(N,L))*(A + (B * (s/t)));

	float specularity  = 0.0;
	float shininess = 50;
	
	if (diffuse > 0){
	vec3 H = normalize(L+V);
	float specularAngle = max(dot(H,N),0.0);
	specularity = pow(specularAngle,shininess);
	}

	if (diffuse < 0) {
		diffuse = 0;
	}
	
	vec3 objectColour = uColor;
	vec3 baseCol = uColor /20;
	float heightColRamp = f_in.heightPos/10;
	if(heightColRamp < 2) {
		heightColRamp = 0;
	}
	vec3 fragColour = ((diffuse + 1 + (f_in.heightPos/10) ) * objectColour) + specularity + baseCol;
	*/

	// output to the frambuffer
	fb_color = vec4(fragColour, 1);
}
