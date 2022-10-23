//
//  atmoshericScattering.cpp
//  CGRA_PROJECT_base
//
//  Created by Zhenchuan Yu on 8/10/22.
//

#include <glm/gtc/constants.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "atmoshericScattering.hpp"

#include "cgra/cgra_shader.hpp"

using namespace std;
using namespace cgra;
using namespace glm;

void AtmoshericScattering::draw(const glm::mat4 &view, const glm::mat4 proj) {
//    mat4 modelview = view * modelTransform;
    
    mat4 m_modelAtmos = glm::scale(glm::mat4(1.0f), glm::vec3(radius_atmosphere, radius_atmosphere, radius_atmosphere));
    mat4 mvp = proj * view * m_modelAtmos;
    
    // Active earth shader and draw earth
    // NOTE:
    // the formula of calculating the MVP in this shader is followed by CGRA350
    // framework
    if (m_drawEarth) {
        mat4 m_modelEarth = glm::scale(glm::mat4(1.0f), glm::vec3(radius_earth, radius_earth, radius_earth));
        mat4 modelview = view * m_modelEarth;
        glUseProgram(shader_earth);
        glUniformMatrix4fv(glGetUniformLocation(shader_earth, "uProjectionMatrix"), 1, false, value_ptr(proj));
        glUniformMatrix4fv(glGetUniformLocation(shader_earth, "uModelViewMatrix"), 1, false, value_ptr(modelview));
        
        glUniform3fv(glGetUniformLocation(shader_earth, "uColor"), 1, value_ptr(color));
        mesh.draw(); // draw
    }
    
    // Active Atmosphere Shader
    // NOTE:
    // The mvp matrix is done in here, shader_atmosphere has different code for
    // calculating the matrix
    glUseProgram(shader_atmosphere); // load shader and variables
    glUniformMatrix4fv(glGetUniformLocation(shader_atmosphere, "MVP"), 1, false, value_ptr(mvp));

    glUniformMatrix4fv(glGetUniformLocation(shader_atmosphere, "M"), 1, false, value_ptr(m_modelAtmos));

    glUniform3fv(glGetUniformLocation(shader_atmosphere, "viewPos"), 1, value_ptr(m_viewPos));

    glUniform1i(glGetUniformLocation(shader_atmosphere, "viewSamples"), viewSamples);
    glUniform1i(glGetUniformLocation(shader_atmosphere, "lightSamples"), lightSamples);
    
    glUniform3fv(glGetUniformLocation(shader_atmosphere, "sunPos"), 1, value_ptr(sunDir));
    glUniform1f(glGetUniformLocation(shader_atmosphere, "I_sun"), intensity_sun);
    
    //cout<<radius_earth<<endl;
    glUniform1f(glGetUniformLocation(shader_atmosphere, "R_e"), radius_earth);
    glUniform1f(glGetUniformLocation(shader_atmosphere, "R_a"), radius_atmosphere);

    glUniform3fv(glGetUniformLocation(shader_atmosphere, "beta_R"), 1, value_ptr(beta_R));
    glUniform1f(glGetUniformLocation(shader_atmosphere, "beta_M"), beta_M);
    glUniform1f(glGetUniformLocation(shader_atmosphere, "H_R"), H_R);
    glUniform1f(glGetUniformLocation(shader_atmosphere, "H_M"), H_M);
    glUniform1f(glGetUniformLocation(shader_atmosphere, "g"), g);
    
    glUniform1f(glGetUniformLocation(shader_atmosphere, "toneMappingFactor"), m_toneMapping * 1.0);

    mesh.draw(); // draw
}

/**
 * Build and return the shader
 */
GLuint AtmoshericScattering::buildScatteringShader() {
    shader_builder sb_atmosphere;
    sb_atmosphere.set_shader(GL_VERTEX_SHADER, CGRA_SRCDIR + std::string("//res//shaders//draw_atmosphere_vert.glsl"));
    sb_atmosphere.set_shader(GL_FRAGMENT_SHADER, CGRA_SRCDIR + std::string("//res//shaders//draw_atmosphere_frag.glsl"));
    GLuint shader_atmosphere = sb_atmosphere.build();
    return shader_atmosphere;
}

/**
 * Build and return the mesh for the earth if the earth is needed
 */
GLuint AtmoshericScattering::buildEarthShader() {
    shader_builder sb_earth;
    sb_earth.set_shader(GL_VERTEX_SHADER, CGRA_SRCDIR + std::string("//res//shaders//color_vert.glsl"));
    sb_earth.set_shader(GL_FRAGMENT_SHADER, CGRA_SRCDIR + std::string("//res//shaders//color_frag.glsl"));
    GLuint shader_earth = sb_earth.build();
    return shader_earth;
}

/**
 * Generate a sphere and return a 'mesh builder'
 *  Code is from my assignment 1
 */
mesh_builder AtmoshericScattering::sphere_latlong(int latDivision_sphere, int lonDivision_sphere) {
    mesh_builder mb;
    vector<vec3> positionsVec;
    vector<vec3> normalsVec;
    vector<vec2> uvsVec;
    vector<unsigned int> indices;
    
    float radius = 1.0f;
    auto pi = glm::pi<float>();
    
    float x, y, z, xy; // vertex position
    float nx, ny, nz, lengthInv = 1.0f / radius; // vertex normal
    
    float latStep = pi / latDivision_sphere; // vertical division
    float lonStep = (2 * pi) / lonDivision_sphere; // horizontal division
    
    float azimuthAngle, elevationAngle;
         
    //iterate through all longitude divisions
    for (int i = 1; i <= latDivision_sphere-1; i++) {
        elevationAngle = pi / 2 - i * latStep; // vertical angle
        xy = radius * cos(elevationAngle);
        z = radius * sin(elevationAngle);
        //iterate through all latitude divisions
        for (int j = 0; j <= lonDivision_sphere; ++j) {
            azimuthAngle = j * lonStep; // horizontal angle starting from 0 to 2pi
                 
            // vertex position (x, y, z)
            x = xy * cosf(azimuthAngle);
            y = xy * sinf(azimuthAngle);
                 
            positionsVec.push_back(vec3(x, z, -y)); // -y makes the point generated counter-clock wise
                 
            // normalized vertex normal (nx, ny, nz)
            nx = x * lengthInv;
            ny = y * lengthInv;
            nz = z * lengthInv;
                 
            normalsVec.push_back(vec3(nx, nz, -ny));
                 
        }
    }

    // vertex tex coord (s, t) range between [0, 1]
    float s, t;
    for (int i = latDivision_sphere-1; i > 0; i--) {
        for (int j = 0; j <= lonDivision_sphere; j++) {
            s = (float)i / latDivision_sphere;
            t = (float)j / lonDivision_sphere;
            uvsVec.push_back(vec2(t, s));
        }
    }
    // add top and bottom UV
    uvsVec.push_back(vec2(0, 1));
    uvsVec.push_back(vec2(0, 0));

    // indices
    int k1, k2;
    for (int i = 0; i < latDivision_sphere -2; ++i) {
        k1 = i * (lonDivision_sphere + 1);
        k2 = k1 + lonDivision_sphere + 1;
             
        for (int j = 0; j < lonDivision_sphere; ++j, ++k1, ++k2) {
            //top left triangle
            indices.push_back(k1);
            indices.push_back(k2);
            indices.push_back(k1 + 1);
            //bottom right triangle
            indices.push_back(k1 + 1);
            indices.push_back(k2);
            indices.push_back(k2 + 1);
        }
    }
    
    // Top
    vec3 top = vec3(0, 1, 0);
    positionsVec.push_back(top);
    vec3 top_n = vec3(0, 1.0f/radius, 0);
    normalsVec.push_back(top_n);
    for (int i = 0; i < lonDivision_sphere; i++) {
        int index = (latDivision_sphere-1)*(lonDivision_sphere+1);
        indices.push_back(index);
        indices.push_back(i);
        indices.push_back(i+1);
    }
    // bottom
    vec3 bottom = vec3(0, -1, 0);
    positionsVec.push_back(bottom);
    vec3 bottom_n = vec3(0, -1.0f/radius, 0);
    normalsVec.push_back(bottom_n);
    for (int i = lonDivision_sphere+1; i > 1; i--) {
        int index = (latDivision_sphere-1)*(lonDivision_sphere+1)+1;
        indices.push_back(index);
        int last_index = (latDivision_sphere-1)*(lonDivision_sphere+1)-i ;
        indices.push_back(last_index);
        indices.push_back(last_index + 1);
    }
    
    for (unsigned int k = 0; k < indices.size(); ++k) {
        mb.push_index(k);
        mb.push_vertex(mesh_vertex{positionsVec[indices[k]], normalsVec[indices[k]], uvsVec[indices[k]]
            });
    }
    
    return mb;
}
