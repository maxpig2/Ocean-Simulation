#version 330 core

#define PI 3.1415926535897932384626433832795

in vec3 fsPosition;     // Position of the fragment
//in vec3 fsNormal;
//in vec2 fsTexCoord;

out vec4 finalColor;

//layout(location = 0) out vec3 finalColor.xyz;

// TODO other constants
uniform vec3 viewPos;   // Position of the viewer
uniform vec3 sunPos;    // Position of the sun, light direction

// Number of samples along the view ray and light ray
uniform int viewSamples;
uniform int lightSamples;

uniform float I_sun;    // Intensity of the sun
uniform float R_e;      // Radius of the planet [m]
uniform float R_a;      // Radius of the atmosphere [m]
uniform vec3  beta_R;   // Rayleigh scattering coefficient
uniform float beta_M;   // Mie scattering coefficient
uniform float H_R;      // Rayleigh scale height
uniform float H_M;      // Mie scale height
uniform float g;        // Mie scattering direction - 
                        //  - anisotropy of the medium

uniform float toneMappingFactor; // Whether tone mapping is applied

/**
 * Computes intersection between a ray and a sphere
 * @param o Origin of the ray
 * @param d Direction of the ray
 * @param r Radius of the sphere
 * @return Roots depending on the intersection
 */
vec2 raySphereIntersection(vec3 o, vec3 d, float r)
{
    // Solving analytically as a quadratic function f(x) = a(x^2) + bx + c
    //  assumes that the sphere is centered at the origin
    float a = dot(d, d);
    float b = 2.0 * dot(d, o);
    float c = dot(o, o) - r * r;

    // Discriminant or delta
    float delta = b * b - 4.0 * a * c;

    // Roots not found
    if (delta < 0.0) {
      return vec2(1e5, -1e5);
    }

    float sqrtDelta = sqrt(delta);
    // return the two roots
    return vec2((-b - sqrtDelta) / (2.0 * a),
                (-b + sqrtDelta) / (2.0 * a));
}

/**
 * Function to compute color of a certain view ray
 * @param ray Direction of the view ray
 * @param origin Origin of the view ray
 * @return color of the view ray
 */
vec3 compute_scattering(vec3 ray, vec3 origin)
{
    // Normalize the light direction
    vec3 sunDir = normalize(sunPos);

    vec2 t = raySphereIntersection(origin, ray, R_a);
    // Intersects behind
    if (t.x > t.y) {
        return vec3(0.0, 0.0, 0.0);
    }
    

    // Distance between samples - length of each segment
    float camera_height = distance(origin, vec3(0,0,0))+0.05;
    t.y = min(t.y, raySphereIntersection(origin, ray, camera_height).x);
    // use radius of earth will wrok but have an artifact
    float segmentLen = (t.y - t.x) / float(viewSamples);

    // Line interperlation t
    float tCurrent = 0.0f; 

    // Rayleigh and Mie contribution
    vec3 sum_R = vec3(0);
    vec3 sum_M = vec3(0);

    // Optical depth 
    float optDepth_R = 0.0;
    float optDepth_M = 0.0;

    // the cosine angle between the sun and ray direction
    float cos_angle = dot(ray, sunDir);
    float cos_angle_sqare = cos_angle * cos_angle;
    
    // Rayleigh and Mie Phase functions
    float phase_R = 3.0 / (16.0 * PI) * (1.0 + cos_angle_sqare);

    float g_2 = g * g;
    float phase_M = 3.0 / (8.0 * PI) *
                          ((1.0 - g_2) * (1.0 + cos_angle_sqare)) /
                          ((2.0 + g_2) * pow(1.0 + g_2 - 2.0 * g * cos_angle, 1.5));
    // Sample along the view ray
    for (int i = 0; i < viewSamples; ++i) {
        // Middle point of the sample position
        vec3 viewSample = origin + ray * (tCurrent + segmentLen * 0.5);

        // Height of the sample above the planet
        float height = length(viewSample) - R_e;

        // Optical depth for Rayleigh and Mie scattering for current sample
        float h_R = exp(-height / H_R) * segmentLen;
        float h_M = exp(-height / H_M) * segmentLen;
        optDepth_R += h_R;
        optDepth_M += h_M;

        
        // light ray (From sample point to the sun)
        float segmentLenLight = raySphereIntersection(viewSample, sunDir, R_a).y / float(lightSamples);
        float tCurrentLight = 0.0;

        // Light optical depth 
        float optDepthLight_R = 0.0;
        float optDepthLight_M = 0.0;

        // Sample along the light ray
        for (int j = 0; j < lightSamples; ++j) {
            // Position of the light ray sample
            vec3 lightSample = viewSample + sunDir * (tCurrentLight + segmentLenLight * 0.5);
            // Height of the light ray sample
            float heightLight = length(lightSample) - R_e;

            // updat opt depth
            optDepthLight_R += exp(-heightLight / H_R) * segmentLenLight;
            optDepthLight_M += exp(-heightLight / H_M) * segmentLenLight;

            // Next light sample
            tCurrentLight += segmentLenLight;
        }

        // Attenuation of the light for both Rayleigh and Mie optical depth
        // Mie extenction coeff. = 1.1 of the Mie scattering coeff.
        vec3 att = exp(-(beta_R * (optDepth_R + optDepthLight_R) + 
                         beta_M * 1.1f * (optDepth_M + optDepthLight_M)));
        // Accucos_anglelate the scattering
        sum_R += h_R * att;
        sum_M += h_M * att;

        // Next view sample
        tCurrent += segmentLen;
    }

    return I_sun * (sum_R * beta_R * phase_R + sum_M * beta_M * phase_M);
}

void main()
{
    vec3 acolor = compute_scattering(normalize(fsPosition - viewPos), viewPos);

    // Apply tone mapping
    acolor = mix(acolor, (1.0 - exp(-1.0 * acolor)), toneMappingFactor);

    finalColor = vec4(acolor, 1.0);
}
