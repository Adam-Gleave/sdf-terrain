#version 440 core

in vec4 v_Colour;

uniform consts {
  vec2 u_Resolution;
};

out vec4 Target0;

const float EPSILON = 0.0001;

float f(float x, float z) {
  return (sin(x) - sin(z)) / 2.0;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
  vec2 xy = gl_FragCoord.xy - size / 2.0;
  float z = size.y / tan(radians(fieldOfView) / 2.0);

  return normalize(vec3(xy, -z));
}

bool marchRay(vec3 origin, vec3 direction, inout float resT )
{
  const float dt = 0.1;
  const float mint = 0.001;
  const float maxt = 100.0;
  
  for (float t = mint; t < maxt; t += dt)
  {
    const vec3 point = origin + direction * t;
    if (point.y < f(point.x, point.z))
    {
        resT = t - 0.5 * dt;
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

  vec3 lightPosition = vec3(0.0, 20.0, 0.0);
  vec3 lightIntensity = vec3(0.2, 0.4, 0.4);

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

mat4 viewMatrix(vec3 eye, vec3 target, vec3 up) {
  vec3 f = normalize(target - eye);
  vec3 s = normalize(cross(f, up));
  vec3 u = cross(s, f);

  return mat4(
    vec4(s, 0.0),
    vec4(u, 0.0),
    vec4(-f, 0.0),
    vec4(0.0, 0.0, 0.0, 1)
  );
}

void main() {
  vec3 dir = rayDirection(45.0, u_Resolution);
  vec3 eye = vec3(40.0, 25.0, 35.0);
  vec3 target = vec3(0.0, 0.0, 0.0);
  vec3 up = vec3(0.0, 1.0, 0.0);

  mat4 worldView = viewMatrix(eye, target, up);
  vec3 worldDir = (worldView * vec4(dir, 0.0)).xyz;

  float t;
  if (marchRay(eye, worldDir, t)) {
    // Lighting calculations
    vec3 point = eye + worldDir * t;
    
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