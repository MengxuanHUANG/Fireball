#version 300 es
precision highp float;

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;

uniform mat4 u_ViewProj;
uniform float u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;

uniform vec4 u_LightPos;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Color;

float random31(vec3 a)
{
    return fract(sin(dot(a, vec3(127.1, 311.7,  74.7))) * (43758.5453f));
}

float interpNoise3D(vec3 p)
{
    int intX = int(floor(p.x));
    float fractX = fract(p.x);
    int intY = int(floor(p.y));
    float fractY = fract(p.y);
    int intZ = int(floor(p.z));
    float fractZ = fract(p.z);

    fractX = fractX * fractX * (3.f - 2.f * fractX);
    fractY = fractY * fractY * (3.f - 2.f * fractY);
    fractZ = fractZ * fractZ * (3.f - 2.f * fractZ);

    float results[2];
    float v[2];
    for(int z = 0; z < 2; ++z)
    {
        for(int y = 0; y < 2; ++y)
        {
            float v1 = random31(vec3(intX, intY + y, intZ + z));
            float v2 = random31(vec3(intX + 1, intY + y, intZ + z));

            v[y] = mix(v1, v2, fractX);
        }
        results[z] = mix(v[0], v[1], fractY);
    }

    return mix(results[0], results[1], fractZ);
}

float NoiseFBM(vec3 p)
{
    float total = 0.0f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = 2.f;
    float amp = 0.5;
    for(int i = 0; i < octaves; ++i)
    {
        total += interpNoise3D(p * freq) * amp;
        freq *= 2.f;
        amp *= persistence;
    }

    return total;
}

void main()
{
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

    vec3 local_pos = vs_Pos.xyz;
    float fbm = NoiseFBM(local_pos);
    
    vec4 modelposition = u_Model * vec4(local_pos, 1.f);   // Temporarily store the transformed vertex positions for use below
    modelposition += fs_Nor * fbm * 0.5f;
    fs_LightVec = u_LightPos - modelposition;
    fs_Color = vec4(0.09f, 0.6f, 0.64f, 1.0f);

    gl_Position = u_ViewProj * modelposition;
}
