#version 440 core

in vec2 a_Pos;
in vec4 a_Colour;
in vec2 vert_Resolution;
out vec4 v_Colour;
out vec2 frag_Resolution;

void main() {
  v_Colour = vec4(a_Colour);
  frag_Resolution = vert_Resolution;
  gl_Position = vec4(a_Pos, 0.0, 1.0);
}