#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec3 u_Right;

uniform vec2 u_Dimensions;
uniform float u_Time;
uniform vec4 u_Fireball_Pos;
uniform mat4 u_Model;
uniform mat4 u_ViewProj;
uniform float u_Raius;

in vec2 fs_UV;

out vec4 out_Col;

float random21(vec2 a)
{
    return fract(sin(dot(a, vec2(127.1, 311.7))) * (43758.5453f));
}

vec3 WorldToUV(in vec4 position)
{
	vec4 screen_space = u_ViewProj * position;
	vec2 uv = screen_space.xy / screen_space.w;;

	return vec3((vec2(1.f) + uv) / vec2(2.f), screen_space.w);
}

vec2 FractalBrownianMotion(vec2 uv)
{
  float amplitude = 4.;
  float frequency = 6.;
  vec2 y = sin(uv * frequency);
  float t = 0.01*(-u_Time);
  y += sin(uv*frequency*2.1 + t)*4.5;
  y += sin(uv*frequency*1.72 + t*1.121)*4.0;
  y += sin(uv*frequency*2.221 + t*0.437)*5.0;
  y += sin(uv*frequency*3.1122+ t*4.269)*2.5;
  y = y * 0.5f + 0.5f;
  return y * amplitude;
}

float parabola(float x, float k)
{
  return pow(4.f * x * (1. - x), k);
}

int squareWave(float x)
{
  return abs(int(floor(x)) % 2);
}

float swtoothWave(float x)
{
  return x - floor(x);
}

int stephWave(float x, int m)
{
  return int(float(abs(int(floor(x)) % m)) / float(m - 1));
}

void main() 
{
  vec3 orange	= vec3( 0.8, 0.65, 0.3);
  vec3 orange_red	= vec3( 0.8f, 0.35f, 0.1f);

  vec3 center_uv = WorldToUV(u_Model * u_Fireball_Pos);
  vec3 radius_uv = WorldToUV((u_Model * u_Fireball_Pos) + vec4(u_Raius * u_Right, 0.0));
  float radius = length((radius_uv.xy - center_uv.xy) * u_Dimensions);
  radius = mix(2.0 * radius, 6.0 * radius, 1.0 / center_uv.z);

  vec2 p = fs_UV - center_uv.xy;
  p *= u_Dimensions;
  float dist = length(p);
  vec2 uv_center = (fs_UV - center_uv.xy);
  float brown = length(FractalBrownianMotion(uv_center));
  radius += brown;

  float fade		= pow( dist / u_Dimensions.x / (0.0006 * radius), 0.5 );
	float fVal1		= 1.0 - fade;
  float corona = pow( fVal1 * max( 1.1 - fade, 0.0 ), 2.0 ) * 50.0;
	corona += pow( fVal1 * max( 1.1 - fade, 0.0 ), 2.0 ) * 50.0;
  float parabola = parabola(clamp(corona, 0., 1.) / 2.f, 1.);

  vec3 color = mix(vec3(0.8f, 0.35f, 0.1f), vec3(0), dist / (radius * 1.5));

  float angle = atan(uv_center.x, uv_center.x);

  float x = u_Time * .01f + (sin(cos(u_Time * 0.001))*.5 + 0.5) * (dist + brown + 7.f) / u_Dimensions.x;
  
  float square_wave = float(squareWave((1.f + 0.2 * (sin(u_Time * 0.05) * 0.5 + 0.5)) * swtoothWave(200. * x + 0.01 * u_Time)));
  square_wave = clamp(square_wave, 0.f, 1.);

  out_Col = vec4(color * ( 1.f + square_wave) + orange * corona * parabola, 1.0);
}
