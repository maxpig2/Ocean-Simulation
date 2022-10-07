float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 calculateDirection(float w) {
	return normalize(vec2(rand(vec2(w,w)), rand(vec2(w+12,w+11))));
}


float waveSpectrumBase(float w){
	return (0.0081 * 9.81 * 9.18)/pow(w,5);
}

float peakFrequency() {
	return (0.855*9.81)/5;
}

float JONSWAP_wp(){
	return 22 * pow((uGravity*uGravity/(uWindSpeed*uOceanFetch)),1.0/3.0);
}

float JONSWAP_r(float w, float sigma) {
	return exp(- pow((w - JONSWAP_wp()),2) / (2*sigma*sigma*JONSWAP_wp()*JONSWAP_wp()));
}


float JONSWAP_sigma(float w) {
	float wp = JONSWAP_wp();
	if (w <= wp) {
		return 0.07;
	}
	return 0.09;
}


float JONSWAP(float w,float R) {
	float sigma = JONSWAP_sigma(w);
	return waveSpectrumBase(w)*pow(R,JONSWAP_r(w,sigma)) * uAmplitude;
}

float usualParameters() {
	return 0.076 * pow(((uWindSpeed*uWindSpeed)/(uOceanFetch*uGravity)),0.22);
}



float calculateAmplitude() {
	return 0.076 * pow((uWindSpeed*uWindSpeed)/(uOceanFetch*uGravity),0.22);
}


float pico (float w) {
	float wp = JONSWAP_wp();
	if (w <= wp) {
		return 5.0;
	}
	return -2.5;
}

float sharpnessFactor(float w) {
	return 11.5 * pow((uGravity/(JONSWAP_wp()*uWindSpeed)),2.5) * pow((w/JONSWAP_wp()),pico(w));
}





float normalizationFactor(float w){
	float sw = sharpnessFactor(w);
	float a = 1.0/2.0*sqrt(3.1415);
	float b = (sw + 1)/(sw*0.5);
	float c = a * b;
	return 5.0;
	return (c);
}

vec2 dispersionRelation(float w) {
	int i  = 2;
	float seedWaveDirectionX = rand(vec2(uWaveSeed * i*i*6 + uWindDirection.x,uWaveSeed * i*i*38+ uWindDirection.y))+0.1;
	float seedWaveDirectionY = rand(vec2(uWaveSeed * i*i + uWindDirection.x,uWaveSeed * i*i+uWindDirection.y))+0.1;
	vec2 dir = normalize(vec2(seedWaveDirectionX, seedWaveDirectionY));
	

	float xDir =  normalizationFactor(w);// * pow(cos((uWindDirection.x - dir.x) / 2),2*sharpnessFactor(w));
	float yDir =  normalizationFactor(w);// * pow(cos((uWindDirection.y - dir.y) / 2),2*sharpnessFactor(w));
	//return vec2(5,1);
	return normalize(vec2(xDir,yDir));
}










vec3 wave(float s, float wL, float p, vec2 dir, vec3 position, float speed, float choppiness){

	dir = calculateDirection(rand(dir));
	//choppiness = sharpnessFactor(choppiness);



	if(choppiness > 1) {
		choppiness = 1;
	}
	if (choppiness < 0){
		choppiness = 0.5;
	}



	float gravity = (uGravity/100);

	float k = 2 * (3.1415/(wL*uWaveLength)) + 5;
	
	float a = (choppiness/k);
	
	float c = sqrt(gravity/k);
	float f = k * (dot(dir, position.xz) - c * uTime * speed);

	float x = position.x + dir.x * (a * cos(f));
	float y = a * sin (f);
	float z = position.z + dir.y * (a * cos(f));

	return vec3(x,y* uAmplitude,z);
}






vec3 waves(int iterations, vec3 position) {
	vec3 gerstnerWave = vec3(0);
	for (int i = 0; i < uWaveNumber; i ++) {
		float period = i + 1;
		float w = 2.0 * 3.1415 * 1.0 / period;

		float seedAmp = rand(vec2(uWaveSeed * i,uWaveSeed * i))+0.1;
		float seedWaveLength = rand(vec2(uWaveSeed * i*i,uWaveSeed * i*i))+0.1;
		float seedWavePeriod = rand(vec2(seedAmp*seedAmp * i*i+20,seedAmp*seedAmp * i*i+20))+0.1;
		float seedWaveDirectionX = rand(vec2(uWaveSeed * i*i*6 + uWindDirection.x,uWaveSeed * i*i*38+ uWindDirection.y))+0.1;
		float seedWaveDirectionY = rand(vec2(uWaveSeed * i*i + uWindDirection.x,uWaveSeed * i*i+uWindDirection.y))+0.1;
		
		float seedWaveSpeed = rand(vec2(uWaveNumber+i, uWaveLength+i))+0.1;
		vec2 direction = normalize(vec2(seedWaveDirectionX, seedWaveDirectionY));
		direction = uWindDirection;

		float amplitude = calculateAmplitude();

		float frequencyMin = 1;
		float frequencyMax = 5;
		float frequencyDivisions = 10;
		float frequencyStep = (frequencyMax - frequencyMin)/frequencyDivisions;

		gerstnerWave += wave( calculateAmplitude() , seedWaveLength, seedWavePeriod, direction, position, seedWaveSpeed*uWindSpeed , 1);

	}
	return gerstnerWave/(uWaveNumber * 1);
}


