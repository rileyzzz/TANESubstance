import lib-sampler.glsl
import lib-vectors.glsl
import lib-env.glsl

// const vec3 light_pos = vec3(10.0, 10.0, 10.0);

//: param custom { "default": 60, "label": "Light Yaw", "min": -180.0, "max": 180.0}
uniform float u_light_yaw;

//: param custom { "default": 60, "label": "Light Pitch", "min": -180.0, "max": 180.0}
uniform float u_light_pitch;

//: param custom { "default": 0.8, "label": "Material Diffuse", "widget": "color" } 
uniform vec3 u_mat_diffuse;

//: param custom { "default": 0.8, "label": "Material Specular", "widget": "color" } 
uniform vec3 u_mat_specular;

//: param custom { "default": 0, "label": "Material Emissive", "widget": "color" } 
uniform vec3 u_mat_emissive;

//: param custom { "default": 1, "label": "Light Diffuse", "widget": "color" } 
uniform vec3 u_light_diffuse;

//: param custom { "default": 1, "label": "Light Specular", "widget": "color" } 
uniform vec3 u_light_specular;

//: param custom { "default": 0.2, "label": "Light Ambient", "widget": "color" } 
uniform vec3 u_light_ambient;

//: param custom { "default": 128, "min": 0.001, "max": 128, "label": "Material Spec Power" } 
uniform float u_spec_power;


struct LightingOutput
{
  vec3 diffColor;
  vec3 specColor;
};

LightingOutput compute_tane_lighting(LocalVectors vectors, vec3 diffuse, vec3 specular, vec3 vecToLight)
{
  LightingOutput output;

  mat3 TBN = mat3(vectors.tangent, vectors.bitangent, vectors.normal);

  // vec3 L = normalize(light_pos - position); 
  // float ndv = dot(vectors.eye, vectors.normal);

  float ndl = max(0.0, dot(vecToLight, vectors.normal));
  vec3 halfAngle = normalize(vectors.eye + vecToLight);

  output.diffColor = ndl * diffuse * u_mat_diffuse;

  float spec = dot(vectors.normal, halfAngle);
  spec = pow(max(spec, 0.0), max(u_spec_power, 0.001));
  output.specColor = spec * specular * u_mat_specular;

  return output;
}

LightingOutput compute_tane_lighting(V2F inputs)
{
  LocalVectors frame = computeLocalFrame(inputs);
  // vec3 vecToLight = normalize(light_pos - inputs.position);

  const float deg2rad = 3.14159265358979323846 / 180.0;

  vec3 lightDir = vec3(cos(u_light_yaw * deg2rad) * cos(u_light_pitch * deg2rad), sin(u_light_yaw * deg2rad) * cos(u_light_pitch * deg2rad), sin(u_light_pitch * deg2rad));

  // Shuffle coordinates.
  lightDir.xyz = lightDir.xzy;
  vec3 vecToLight = normalize(lightDir);

  LightingOutput output = compute_tane_lighting(frame, u_light_diffuse, u_light_specular, vecToLight);

  // Add ambient.
  output.diffColor += u_mat_diffuse * u_light_ambient;

  output.diffColor += u_mat_emissive;

  // output.diffColor.a = u_mat_diffuse.a;

  return output;
}
//: param auto channel_basecolor 
uniform SamplerSparse basecolor_tex;

//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;

//: param auto channel_glossiness
uniform SamplerSparse glossiness_tex;

vec4 shade(V2F inputs) 
{
  vec3 color = getBaseColor(basecolor_tex, inputs.sparse_coord); 
  float specMask = textureSparse(specularlevel_tex, inputs.sparse_coord).r;
  float gloss = textureSparse(glossiness_tex, inputs.sparse_coord).r;

  LightingOutput lighting = compute_tane_lighting(inputs);

  // diffuseShadingOutput(lighting.diffColor * color); 
  // specularShadingOutput(lighting.specColor * specMask); 
  vec3 fragColor = lighting.diffColor * color + lighting.specColor * specMask;

  // Blend in envmap.
  LocalVectors frame = computeLocalFrame(inputs);
  vec3 reflectVec = reflect(-frame.eye, frame.normal).xyz;

  // Shuffle coordinates.
  // reflectVec.xyz = reflectVec.xzy;
  // vec3 reflectColor = texture(u_environment_texture, reflectVec).rgb;
  vec3 reflectColor = envSampleLOD(reflectVec, 0).rgb;
  reflectColor = pow(reflectColor, vec3(2.2, 2.2, 2.2));

  fragColor.rgb = mix(fragColor.rgb, reflectColor.rgb, gloss);

  // albedoOutput(fragColor);
  // diffuseShadingOutput(fragColor); 
  return vec4(fragColor, 1);
}