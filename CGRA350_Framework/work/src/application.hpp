
#pragma once

// glm
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>

// project
#include "opengl.hpp"
#include "cgra/cgra_mesh.hpp"
#include "skeleton_model.hpp"
#include "atmoshericScattering.hpp"


// Basic model that holds the shader, mesh and transform for drawing.
// Can be copied and modified for adding in extra information for drawing
// including textures for texture mapping etc.
struct basic_model {
	GLuint shader = 0;
	cgra::gl_mesh mesh;
	glm::vec3 color{0,0.2,0.7};
	glm::mat4 modelTransform{1.0};
	GLuint texture;
	GLfloat time;
	GLfloat amplitude = 1;
	GLfloat waveLength = 1;
	glm::vec2 windDirection{0,1};
	GLfloat gravity = 9.81;
	GLfloat seed = 1.4872;
	GLint waveNumber = 15;
	GLfloat oceanFetch = 5;
	GLfloat windSpeed = 10;
	GLfloat choppiness = 0.5;
	GLfloat oceanSpeed = 10;
	GLfloat oceanPos = 0;
	glm::vec3 oceanLightPosition = vec3(0,0.5,1);
	glm::vec3 oceanCamPos = vec3(1,4,0);




	void draw(const glm::mat4 &view, const glm::mat4 proj);
};


// Main application class
//
class Application {
private:
	// window
	glm::vec2 m_windowsize;
	GLFWwindow *m_window;

	// oribital camera
	float m_pitch = 0.00;
	float m_yaw = -1.55;
	float m_distance = 20;
	glm::vec2 m_cam_pos;

	// last input
	bool m_leftMouseDown = false;
	bool m_rightMouseDown = false;
	bool m_middleMouseDown = false;
	glm::vec2 m_mousePosition;

	// drawing flags
	bool m_show_axis = false;
	bool m_show_grid = false;
	bool m_showWireframe = false;

	// geometry
	basic_model m_model;
	AtmoshericScattering scattering;

	//Constants
	const float PI = glm::pi<float>();

	//Textures
	GLuint m_texture;
	GLuint m_normal;


public:
	// setup
	Application(GLFWwindow *);

	// disable copy constructors (for safety)
	Application(const Application&) = delete;
	Application& operator=(const Application&) = delete;

	// rendering callbacks (every frame)
	void render();
	void renderGUI();

	// input callbacks
	void cursorPosCallback(double xpos, double ypos);
	void mouseButtonCallback(int button, int action, int mods);
	void scrollCallback(double xoffset, double yoffset);
	void keyCallback(int key, int scancode, int action, int mods);
	void charCallback(unsigned int c);

	//Implicitly creates a sphere
	cgra::gl_mesh createOceanMesh(float subdivisions, float radius);
};
