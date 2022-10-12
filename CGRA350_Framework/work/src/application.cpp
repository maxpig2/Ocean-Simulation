
// std
#include <iostream>
#include <string>
#include <chrono>
#include <stdio.h>
#include <stdlib.h>

// glm
#include <glm/gtc/constants.hpp>
#include <glm/gtc/matrix_transform.hpp>

// project
#include "application.hpp"
#include "cgra/cgra_geometry.hpp"
#include "cgra/cgra_gui.hpp"
#include "cgra/cgra_image.hpp"
#include "cgra/cgra_shader.hpp"
#include "cgra/cgra_wavefront.hpp"


using namespace std;
using namespace cgra;
using namespace glm;


void basic_model::draw(const glm::mat4 &view, const glm::mat4 proj) {
	mat4 modelview = view * modelTransform;
	
	glUseProgram(shader); // load shader and variables
	glUniformMatrix4fv(glGetUniformLocation(shader, "uProjectionMatrix"), 1, false, value_ptr(proj));
	glUniformMatrix4fv(glGetUniformLocation(shader, "uModelViewMatrix"), 1, false, value_ptr(modelview));
	glUniform3fv(glGetUniformLocation(shader, "uColor"), 1, value_ptr(color));
	glUniform1f(glGetUniformLocation(shader, "uTime"), time);
	glUniform1f(glGetUniformLocation(shader, "uAmplitude"), amplitude);
	glUniform1f(glGetUniformLocation(shader, "uWaveLength"), waveLength);
	glUniform2fv(glGetUniformLocation(shader, "uWindDirection"), 1 , value_ptr(windDirection));
	glUniform1f(glGetUniformLocation(shader, "uGravity"), gravity);
	glUniform1f(glGetUniformLocation(shader, "uWaveSeed"), seed);
	glUniform1i(glGetUniformLocation(shader, "uWaveNumber"), waveNumber);
	glUniform1i(glGetUniformLocation(shader, "uOceanFetch"), (oceanFetch*1000));
	glUniform1f(glGetUniformLocation(shader, "uWindSpeed"), windSpeed);
	glUniform1f(glGetUniformLocation(shader, "uChoppiness"), choppiness);
	glUniform1f(glGetUniformLocation(shader, "uOceanSpeed"), oceanSpeed);

//

	
	cout << "amplitudeCalculated :" << 0.076 * pow((windSpeed*windSpeed)/(oceanFetch*gravity),0.22) << endl;
	cout << "amplitudeMultipledByUAmp :" << 0.076 * pow((windSpeed*windSpeed)/(oceanFetch*gravity),0.22)*amplitude << endl;

	//drawCylinder();
	//drawSphere();
	mesh.draw(); // draw
	//cout<< "windSpeed : " << windSpeed <<endl;
}




Application::Application(GLFWwindow *window) : m_window(window) {
	
	shader_builder sb;

	std::ifstream fileStream1(CGRA_SRCDIR + std::string("//res//shaders//ocean_wave_vert.glsl"));

		std::stringstream vert;
		vert << fileStream1.rdbuf();

	std::ifstream fileStream2(CGRA_SRCDIR + std::string("//res//shaders//ocean_wave_frag.glsl"));

		std::stringstream frag;
		frag << fileStream2.rdbuf();	

	std::ifstream fileStream3(CGRA_SRCDIR + std::string("//res//shaders//waves.glsl"));

		std::stringstream wave;
		wave << fileStream3.rdbuf();	

    sb.set_shader_source(GL_VERTEX_SHADER, vert.str()+wave.str());
	sb.set_shader_source(GL_FRAGMENT_SHADER, frag.str()+wave.str());
	//sb.set_shader(GL_FRAGMENT_SHADER, CGRA_SRCDIR + std::string("//res//shaders//oren_nayar_frag.glsl"));
	

	GLuint shader = sb.build();

	m_texture = rgba_image(CGRA_SRCDIR + std::string("/res//textures//Texture.png")).uploadTexture(GL_RGBA8,0);
	m_normal = rgba_image(CGRA_SRCDIR + std::string("/res//textures//NormalMap.png")).uploadTexture(GL_RGBA8,0);
	

	m_model.shader = shader;
	m_model.mesh = load_wavefront_data(CGRA_SRCDIR + std::string("/res//assets//teapot.obj")).build();
	m_model.mesh = createOceanMesh(100,20);
	m_model.color = vec3(0, 0.3, 0.5);
	m_cam_pos = vec2( 0, 0 );
}


void Application::render() {
	
	// retrieve the window height
	int width, height;
	glfwGetFramebufferSize(m_window, &width, &height); 

	m_windowsize = vec2(width, height); // update window size
	glViewport(0, 0, width, height); // set the viewport to draw to the entire window

	// clear the back-buffer
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); 

	// enable flags for normal/forward rendering
	glEnable(GL_DEPTH_TEST); 
	glDepthFunc(GL_LESS);

	// projection matrix
	mat4 proj = perspective(1.f, float(width) / height, 0.1f, 1000.f);

	// view matrix
	mat4 view = translate(mat4(1), vec3( m_cam_pos.x, m_cam_pos.y, -m_distance))
		* rotate(mat4(1), m_pitch, vec3(1, 0, 0))
		* rotate(mat4(1), m_yaw,   vec3(0, 1, 0));


	// helpful draw options
	if (m_show_grid) drawGrid(view, proj);
	if (m_show_axis) drawAxis(view, proj);
	glPolygonMode(GL_FRONT_AND_BACK, (m_showWireframe) ? GL_LINE : GL_FILL);

	
	/*
	//Textures
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, m_texture);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, m_normal);
	*/

	m_model.time += 0.01;
	// draw the model
	m_model.draw(view, proj);
}


//Shape Attributes
int oceanMeshDivisions = 100;
int oceanMeshRadius = 20;

void Application::renderGUI() {

	// setup window
	ImGui::SetNextWindowPos(ImVec2(5, 5), ImGuiSetCond_Once);
	ImGui::SetNextWindowSize(ImVec2(600, 300), ImGuiSetCond_Once);
	ImGui::Begin("Options", 0);

	// display current camera parameters
	ImGui::Text("Application %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
	ImGui::SliderFloat("Pitch", &m_pitch, -pi<float>() / 2, pi<float>() / 2, "%.2f");
	ImGui::SliderFloat("Yaw", &m_yaw, -pi<float>(), pi<float>(), "%.2f");
	ImGui::SliderFloat("Distance", &m_distance, 0, 100, "%.2f", 2.0f);

	// helpful drawing options
	ImGui::Checkbox("Show axis", &m_show_axis);
	ImGui::SameLine();
	ImGui::Checkbox("Show grid", &m_show_grid);
	ImGui::Checkbox("Wireframe", &m_showWireframe);
	ImGui::SameLine();
	if (ImGui::Button("Screenshot")) rgba_image::screenshot(true);

	ImGui::Separator();
	ImGui::Text("Mesh");
	// example of how to use input boxes
	if (ImGui::Button("Teapot")){
		m_model.mesh = load_wavefront_data(CGRA_SRCDIR + std::string("/res//assets//teapot.obj")).build();
	}
	ImGui::SameLine();
	if (ImGui::Button("Ocean Mesh")){
		m_model.mesh = createOceanMesh(oceanMeshDivisions, oceanMeshRadius);
	}

/*
	ImGui::Separator();
	
	ImGui::Text("Shaders");
	ImGui::SameLine();
	if (ImGui::Button("Oren Nayar")){
		shader_builder sb;
   		sb.set_shader(GL_VERTEX_SHADER, CGRA_SRCDIR + std::string("//res//shaders//ocean_wave_vert.glsl"));
		sb.set_shader(GL_FRAGMENT_SHADER, CGRA_SRCDIR + std::string("//res//shaders//oren_nayar_frag.glsl"));
		GLuint shader = sb.build();
		m_model.shader = shader;
	}
	*/

	ImGui::Separator();
	ImGui::Text("Ocean Mesh Attributes");
	if (ImGui::InputInt("Wave Divisions", &oceanMeshDivisions)) {m_model.mesh = createOceanMesh(oceanMeshDivisions, oceanMeshRadius);}
	if (ImGui::InputInt("Wave Size", &oceanMeshRadius)) {m_model.mesh = createOceanMesh(oceanMeshDivisions, oceanMeshRadius);}
	if (ImGui::InputFloat("Wave Amplitude", &m_model.amplitude)) {}
	if (ImGui::InputFloat("Wave Length", &m_model.waveLength)) {}
	if (ImGui::SliderFloat2("Wind Direction", value_ptr(m_model.windDirection),0,1,"%.2f")) {}
	if (ImGui::InputFloat("Gravity", &m_model.gravity)) {}
	if (ImGui::InputFloat("Ocean Seed", &m_model.seed)) {}
	if (ImGui::InputInt("Wave Number", &m_model.waveNumber)) {}

	if (ImGui::InputFloat("Ocean Fetch", &m_model.oceanFetch)) {}
	if (ImGui::InputFloat("Wind Speed", &m_model.windSpeed)) {}
	if (ImGui::SliderFloat("Ocean Choppiness", (&m_model.choppiness),0,1,"%.2f")) {}
	if(ImGui::SliderFloat3("Ocean Colour", value_ptr(m_model.color),0,1,"%.2f")){}
	
	

	ImGui::Separator();
	ImGui::Text("Presets");
	if(ImGui::Button("Reset Ocean")){
		m_model.amplitude = 1;
		m_model.waveLength = 1;
		m_model.gravity = 9.81;
		m_model.waveNumber = 10;
		oceanMeshDivisions = 100;
		oceanMeshRadius = 20;
		m_model.mesh = createOceanMesh(oceanMeshDivisions, oceanMeshRadius);
		m_model.oceanFetch = 10;
		m_model.windSpeed = 10;
		m_model.choppiness = 0.5;
		m_model.color = vec3(0, 0.3, 0.5);
	}
	ImGui::SameLine();
	if(ImGui::Button("Large Ocean")){
		m_model.amplitude = 20;
		m_model.waveLength = 1;
		m_model.gravity = 9.81;
		m_model.waveNumber = 25;
		oceanMeshDivisions = 200;
		oceanMeshRadius = 40;
		m_model.mesh = createOceanMesh(oceanMeshDivisions, oceanMeshRadius);
		m_model.oceanFetch = 8;
		m_model.windSpeed = 10;
		m_model.choppiness = 0.2;
	}
	ImGui::SameLine();
	if(ImGui::Button("Tropical Ocean")){

		m_model.color = vec3(0, 0.44, 0.80);
	}
	
	


	// finish creating window
	ImGui::End();
}


void Application::cursorPosCallback(double xpos, double ypos) {
	vec2 whsize = m_windowsize / 2.0f;

	double y0 = glm::clamp((m_mousePosition.y - whsize.y) / whsize.y, -1.0f, 1.0f);
	double y = glm::clamp((float(ypos) - whsize.y) / whsize.y, -1.0f, 1.0f);
	double dy = -( y - y0 );

	double x0 = glm::clamp((m_mousePosition.x - whsize.x) / whsize.x, -1.0f, 1.0f);
	double x = glm::clamp((float(xpos) - whsize.x) / whsize.x, -1.0f, 1.0f);
	double dx = x - x0;

	if (m_leftMouseDown) {
		// clamp the pitch to [-pi/2, pi/2]
		m_pitch += float( acos(y0) - acos(y) );
		m_pitch = float(glm::clamp(m_pitch, -pi<float>() / 2, pi<float>() / 2));

		// wrap the yaw to [-pi, pi]
		m_yaw += float( acos(x0) - acos(x) );
		if (m_yaw > pi<float>()) 
			m_yaw -= float(2 * pi<float>());
		else if (m_yaw < -pi<float>()) 
			m_yaw += float(2 * pi<float>());
	} else if ( m_rightMouseDown ) {
		m_distance += dy * 10;
	} else if ( m_middleMouseDown ) {
		m_cam_pos += vec2( dx, dy ) * 10.f;
	}

	// updated mouse position
	m_mousePosition = vec2(xpos, ypos);
}


void Application::mouseButtonCallback(int button, int action, int mods) {
	(void)mods; // currently un-used

	// capture is left-mouse down
	if (button == GLFW_MOUSE_BUTTON_LEFT)
		m_leftMouseDown = (action == GLFW_PRESS); // only other option is GLFW_RELEASE
	else if (button == GLFW_MOUSE_BUTTON_RIGHT)
		m_rightMouseDown = (action == GLFW_PRESS);
	else if (button == GLFW_MOUSE_BUTTON_MIDDLE)
		m_middleMouseDown = (action == GLFW_PRESS);
}


void Application::scrollCallback(double xoffset, double yoffset) {
	(void)xoffset; // currently un-used
	m_distance *= pow(1.1f, -yoffset);
}


void Application::keyCallback(int key, int scancode, int action, int mods) {
	(void)key, (void)scancode, (void)action, (void)mods; // currently un-used
}


void Application::charCallback(unsigned int c) {
	(void)c; // currently un-used
}

gl_mesh Application::createOceanMesh(float subdivisions, float radius){
	mesh_builder cube;
	//Object Information
	vector<vec3> positions;
	vector<vec3> normals;
	vector<vec2> uvs;
	vector<int> indices;

	for (int i = 0; i <= subdivisions; i++) {
		for (int j = 0; j <= subdivisions; j++) {
			float x  = -((i-(subdivisions/2))/(subdivisions/2));
			float y = 0;
			float z = ((j-(subdivisions/2))/(subdivisions/2));
			float xSquared = x*x;
			float ySquared = y*y;
			float zSquared = z*z;	
			x *= radius;
			z *= radius;
			positions.push_back(vec3(x,y,z));
			normals.push_back(vec3(0,1,0));
		}
	}

for (int i = 0; i <= subdivisions; i++){
	if (i != subdivisions && i != subdivisions * 2 + 1 && i != subdivisions * 3 + 2 && i != subdivisions * 4 + 3 && i != subdivisions * 5 + 4) {
		int m = i * (subdivisions + 1);
		int n = m + subdivisions + 1;
		for (int j = 0; j < subdivisions; j++, m++, n++) {
            	//Define the bottom triangle
                 indices.push_back(m);
                 indices.push_back(n);
                 indices.push_back(m + 1); 
				//Define the top triangle
                indices.push_back(m + 1);
                indices.push_back(n);
                indices.push_back(n + 1);
		}
	}
}
	for (int k = 0; k < indices.size(); ++k) {
             cube.push_index(k);
             cube.push_vertex(mesh_vertex{
                 positions[indices[k]],
                 normals[indices[k]]
             });
         }
	return cube.build();
}
