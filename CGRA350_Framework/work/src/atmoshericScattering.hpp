//
//  atmoshericScattering.hpp
//  CGRA_PROJECT_base
//
//  Created by Zhenchuan Yu on 8/10/22.
//


#include <stdio.h>
#include <glm/glm.hpp>

#include "opengl.hpp"
#include "cgra/cgra_mesh.hpp"
#include "skeleton_model.hpp"

using namespace std;
using namespace cgra;
using namespace glm;

struct AtmoshericScattering {
    GLuint shader_earth = 0;
    GLuint shader_atmosphere = 0;
    cgra::gl_mesh mesh;
    glm::vec3 color{0.7};
    glm::mat4 modelTransform{1.0};
    GLuint texture;
    
    // Setting
    float intensity_sun = 20.0f; // sun intensity
    float sunAngle = glm::radians(1.f); // sun angle
    glm::vec3 sunDir = glm::vec3(0, glm::sin(sunAngle), -glm::cos(sunAngle));
    
    float radius_atmosphere = 6390.; // 6550.
    float radius_earth = 6359.; //6360.
    
    int viewSamples = 16;
    int lightSamples = 8;
    
    float H_R = 7.994; // H0 term in Rayleigh
    float H_M = 1.200; // H0 term in Mie
    float g = 0.980; // Anisotropy
    float beta_M = 21e-3f; // Mie Coefficient
    glm::vec3 beta_R = glm::vec3(5.8e-3f, 13.5e-3f, 33.1e-3f); // Rayleigh Coefficient
    
    glm::vec3 m_viewPos = glm::vec3(0.0, 6359, 0.0);
    glm::vec3 front;
    
    bool m_toneMapping = true;
    bool m_drawEarth = false;
    
    GLuint buildScatteringShader();
    GLuint buildEarthShader();
    mesh_builder sphere_latlong(int latDivision_sphere, int lonDivision_sphere);
    void draw(const glm::mat4 &view, const glm::mat4 proj);
    
};
