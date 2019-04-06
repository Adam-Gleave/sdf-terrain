#version 440 core

in vec2 a_Pos;
in vec4 a_Colour;

uniform consts {
  vec2 u_Resolution;
};

out vec4 v_Colour;

void main() {
  v_Colour = vec4(a_Colour);
  gl_Position = vec4(a_Pos, 0.0, 1.0);
}