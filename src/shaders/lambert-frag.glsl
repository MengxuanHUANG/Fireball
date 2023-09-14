#version 300 es
precision highp float;
out vec4 fs_Col;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Color;

void main()
{
    vec4 diffuseColor = fs_Color; 

    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    diffuseTerm = mix(0.f, .9f, diffuseTerm * 0.5f +0.5f);
    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;
    float brightness = 1.7f;
    fs_Col = vec4((diffuseColor * brightness).xyz, diffuseColor.a);
}
