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



float calculateAmplitude(float w) {
	return (0.076 * pow((uWindSpeed*uWindSpeed)/(uOceanFetch*uGravity),0.22))*w;
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
	//return 5.0;
	return (c);
}

vec2 dispersionRelation(float w) {
	int i  = 2;
	float seedWaveDirectionX = rand(vec2(uWaveSeed * i*i*6 + uWindDirection.x,uWaveSeed * i*i*38+ uWindDirection.y))+0.1;
	float seedWaveDirectionY = rand(vec2(uWaveSeed * i*i + uWindDirection.x,uWaveSeed * i*i+uWindDirection.y))+0.1;
	vec2 dir = normalize(vec2(seedWaveDirectionX, seedWaveDirectionY));
	

	float xDir =  normalizationFactor(w) * pow(cos((uWindDirection.x - dir.x) / 2),2*sharpnessFactor(w));
	float yDir =  normalizationFactor(w) * pow(cos((uWindDirection.y - dir.y) / 2),2*sharpnessFactor(w));
	//return vec2(5,1);
	return normalize(vec2(xDir,yDir)+vec2(seedWaveDirectionX,seedWaveDirectionY));
}










vec3 wave(float amp, float wL, vec2 dir, vec3 position, float speed, float choppiness){

	dir = calculateDirection(rand(dir));


	choppiness = sharpnessFactor(choppiness);
	//amp = calculateAmplitude(amp);
	//amp *= (uAmplitude) ;

	choppiness = choppiness * uChoppiness;


	if(choppiness > 1) {
		choppiness = 1;
	}
	if (choppiness < 0){
		choppiness = 0.0;
	}



	float gravity = (uGravity/10);

	float k = 2 * (3.1415/(wL*uWaveLength));
	
	float a = (choppiness/k);
	
	float c = sqrt(gravity/k);
	float f = k * (dot(dir, position.xz) - c * uTime * uOceanSpeed * speed);

	float x = position.x + dir.x * (a * cos(f));
	float y = a * sin (f);
	float z = position.z + dir.y * (a * cos(f));

	return vec3(x,y * uAmplitude,z);
}






vec3 waves(int iterations, vec3 position) {
	vec3 gerstnerWave = vec3(0);

	float amp = 1;
	float waveLen = 5;
	float waveSpe = 0.5;

	for (int i = uWaveNumber; i > 0; i --) {


		


		float w = 2.0 * 3.1415 * 1.0 + i;
		//w = rand(vec2(w,w*2));amp

		float calculatedAmp = calculateAmplitude(amp);

		float seedAmp = rand(vec2(uWaveSeed * amp,uWaveSeed))+0.1;
	//	seedAmp *= calculateAmplitude(seedAmp);

		float seedWaveLength = rand(vec2(uWaveSeed * i*i,uWaveSeed * i*i))+0.1;
		float seedWavePeriod = rand(vec2(seedAmp*seedAmp * i*i+20,seedAmp*seedAmp * i*i+20))+0.1;
		float seedWaveDirectionX = rand(vec2(uWaveSeed * i*i*6 + uWindDirection.x,uWaveSeed * i*i*38+ uWindDirection.y))+0.1;
		float seedWaveDirectionY = rand(vec2(uWaveSeed * i*i + uWindDirection.x,uWaveSeed * i*i+uWindDirection.y))+0.1;
		
		float seedWaveSpeed = rand(vec2(uWaveNumber+i, uWaveLength+i))+0.1;
		vec2 direction = normalize(vec2(seedWaveDirectionX, seedWaveDirectionY));


		float seed_wave = rand(vec2(uWaveSeed * i * 20 +0.2, i*i * 34 +0.6)) * 100 + 0.1;
		float amplitude_wave = calculateAmplitude(seed_wave) * amp;
		float length_wave = waveLen * uWaveLength + 0.1;
		vec2  direction_wave = dispersionRelation(seed_wave);
		float speed_wave = waveSpe + (uWindSpeed/10) + 0.1;
		float sharpness_wave = 1;

		gerstnerWave += wave(amplitude_wave, length_wave, direction_wave, position, speed_wave, sharpness_wave);
		

		//gerstnerWave += wave(pow(calculateAmplitude(seedAmp)*amp,2), waveLen*uWaveLength + 0.1, dispersionRelation(waveSeed), position, waveSpe * (uWindSpeed/10) + .1, sharpnessFactor(i));
		//gerstnerWave += wave( seedAmp*uOceanFetch, seedWaveLength+i, direction, position, seedWaveSpeed + i , 1);
		//gerstnerWave += wave(seedAmp*uOceanFetch, seedWaveLength, direction, position, i/5 , sharpnessFactor(seedAmp*i));
		//gerstnerWave+= wave(seedAmp*uOceanFetch+i, seedWaveLength*15, direction, position, seedWaveSpeed + (i/10) , sharpnessFactor(seedAmp*i));

		amp *= 0.4;
		waveLen *= 0.9;
		waveSpe *= 0.85;


	}
	gerstnerWave.xz /= uWaveNumber;

	return gerstnerWave;
}



