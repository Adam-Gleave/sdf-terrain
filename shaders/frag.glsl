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

vec3 estimateNormal(vec3 point) {
    return normalize(vec3(
        sceneSDF(vec3(point.x + EPSILON, point.y, point.z)) - 
        sceneSDF(vec3(point.x - EPSILON, point.y, point.z)),
        
        sceneSDF(vec3(point.x, point.y + EPSILON, point.z)) -
        sceneSDF(vec3(point.x, point.y - EPSILON, point.z)),
        
        sceneSDF(vec3(point.x, point.y, point.z  + EPSILON)) - 
        sceneSDF(vec3(point.x, point.y, point.z - EPSILON))
    ));
}

vec3 phongAddForLight(
  vec3 diffuse_colour,
  vec3 specular_colour,
  float shininess,
  vec3 lightPosition,
  vec3 lightIntensity,
  vec3 point,
  vec3 eye
) {
  vec3 n = estimateNormal(point);
  vec3 l = normalize(lightPosition - point);
  vec3 r = normalize(eye - point);
  vec3 v = normalize(reflect(-l, n));

  float dotLN = dot(l, n);
  float dotRV = dot(r, v);

  if (dotLN < 0.0) {
    return vec3(0.0, 0.0, 0.0);
  }

  if (dotRV < 0.0) {
    return lightIntensity * (diffuse_colour * dotLN);
  }

  return lightIntensity * (diffuse_colour * dotLN + specular_colour * pow(dotRV, shininess));
}

vec3 phongIllumination(
  vec3 ambient_colour,
  vec3 diffuse_colour,
  vec3 specular_colour,
  float shininess,
  vec3 point,
  vec3 eye
) {
  const vec3 ambientLight = 0.025 * vec3(0.8, 0.8, 0.8);
  vec3 colour = ambient_colour * ambientLight;

  vec3 lightPosition = vec3(2.0, 2.0, 2.0);
  vec3 lightIntensity = vec3(0.4, 0.4, 0.4);

  vec3 light2Position = vec3(-3.0, -1.5, 1.0);
  vec3 light2Intensity = vec3(0.05, 0.05, 0.05);

  colour += phongAddForLight(
    diffuse_colour,
    specular_colour,
    shininess,
    lightPosition,
    lightIntensity,
    point,
    eye
  );

  colour += phongAddForLight(
    diffuse_colour,
    specular_colour,
    shininess,
    light2Position,
    light2Intensity,
    point,
    eye
  );

  return colour;
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

  // Lighting calculations
  vec3 point = eye + dir * dist;
  
  vec3 ambient_colour = vec3(0.4, 0.15, 0.15);
  vec3 diffuse_colour = vec3(0.9, 0.15, 0.15);
  vec3 specular_colour = vec3(1.0, 1.0, 1.0);
  float shininess = 5.0;

  vec3 colour = phongIllumination(
    ambient_colour,
    diffuse_colour,
    specular_colour,
    shininess,
    point,
    eye
  );

  Target0 = vec4(colour, 1.0);
}