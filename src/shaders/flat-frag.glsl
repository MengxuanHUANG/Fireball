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

vec3 WorldToUV(in vec4 position)
{
	vec4 screen_space = u_ViewProj * position;
	vec2 uv = screen_space.xy / screen_space.w;;

	return vec3((vec2(1.f) + uv) / vec2(2.f), screen_space.w);
}

void main() 
{
  vec3 orange	= vec3( 0.8, 0.65, 0.3);
  vec3 orange_red	= vec3( 0.8f, 0.35f, 0.1f);

  vec3 center_uv = WorldToUV(u_Model * u_Fireball_Pos);
  vec3 radius_uv = WorldToUV((u_Model * u_Fireball_Pos) + vec4(u_Raius * u_Right, 0.0));
  float radius = length((radius_uv.xy - center_uv.xy) * u_Dimensions);
  radius = mix(2.0 * radius, 10.0 * radius, 1.0 / center_uv.z);

  vec2 p = fs_UV - center_uv.xy;
  p *= u_Dimensions;
  float fade		= pow( length( p ) / u_Dimensions.x / (0.0006 * radius), 0.5 );
	float fVal1		= 1.0 - fade;
  float fVal2		= 1.0 - fade;
  float corona = pow( fVal1 * max( 1.1 - fade, 0.0 ), 2.0 ) * 50.0;
	corona += pow( fVal1 * max( 1.1 - fade, 0.0 ), 2.0 ) * 50.0;
  
  float dist = length((fs_UV - center_uv.xy) * u_Dimensions);
  vec3 color = mix(vec3(0.8f, 0.35f, 0.1f), vec3(0), dist / (radius * 1.5));
  //out_Col = vec4(0.5 * (fs_UV + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
  float starGlow	= min( max( 1.0 - dist / (radius), 0.0 ), 1.0 );

  out_Col = vec4(color + orange * corona, 1.0);
}
