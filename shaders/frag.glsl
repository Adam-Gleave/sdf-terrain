#version 440 core

in vec4 v_Colour;
in vec2 frag_Resolution;
out vec4 Target0;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

float sphereSDF(vec3 point) {
  return length(point) - 1.0;
}

float sceneSDF(vec3 point) {
  return sphereSDF(point);
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
  float depth = start;
  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
    float dist = sceneSDF(eye + depth * marchingDirection);
    if (dist < EPSILON) {
      return depth;
    }
    depth += dist;
    if (depth >= end) {
      return end;
    }
  }
  return end;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
  vec2 xy = gl_FragCoord.xy - size / 2.0;
  float z = size.y / tan(radians(fieldOfView) / 2.0);

  return normalize(vec3(xy, -z));
}

void main() {
  vec3 dir = rayDirection(45.0, frag_Resolution);
  vec3 eye = vec3(0.0, 0.0, 5.0);
  float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);

  if (dist > MAX_DIST - EPSILON) {
    // Did not hit anything
    Target0 = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  Target0 = vec4(1.0, 0.0, 0.0, 1.0);
}