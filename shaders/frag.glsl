#version 440 core

in vec4 v_Colour;

uniform consts {
  vec2 u_Resolution;
};

out vec4 Target0;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

float f(float x, float z) {
  return 0.0;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
  vec2 xy = gl_FragCoord.xy - size / 2.0;
  float z = size.y / tan(radians(fieldOfView) / 2.0);

  return normalize(vec3(xy, -z));
}

bool marchRay(vec3 origin, vec3 direction, inout float resT )
{
  const float dt = 0.01f;
  const float mint = 0.001f;
  const float maxt = 10.0f;
  
  for (float t = mint; t < maxt; t += dt)
  {
    const vec3 point = origin + direction * t;
    if (point.y < f( point.x, point.z ))
    {
        resT = t - 0.5f*dt;
        return true;
    }
  }
  return false;
}

vec3 estimateNormal(vec3 point)
{
  return normalize(vec3(
    f(point.x - EPSILON, point.z) - f(point.x + EPSILON, point.z),
    2.0f * EPSILON,
    f(point.x, point.z - EPSILON) - f(point.x, point.z + EPSILON)
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

  colour += phongAddForLight(
    diffuse_colour,
    specular_colour,
    shininess,
    lightPosition,
    lightIntensity,
    point,
    eye
  );

  return colour;
}

vec3 skyColour() {
  return vec3(0.6, 0.75, 1.0);
}

void main() {
  vec3 dir = rayDirection(45.0, u_Resolution);
  vec3 eye = vec3(0.0, 1.0, 5.0);

  float t;
  if (marchRay(eye, dir, t)) {
    // Lighting calculations
    vec3 point = eye + dir * t;
    
    vec3 ambient_colour = vec3(0.15, 0.4, 0.15);
    vec3 diffuse_colour = vec3(0.2, 0.8, 0.2);
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
  else {
    Target0 = vec4(skyColour(), 1.0);
  }
}