
//: param auto channel_basecolor 
uniform SamplerSparse basecolor_tex;

//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;

//: param auto channel_glossiness
uniform SamplerSparse glossiness_tex;

//: param custom { "default": "env_metal", "label": "Env Map" }
uniform sampler2D reflection_tex;

//: param custom { "default": 1.0, "label": "Material Reflection Amount", "min": 0.0, "max": 1.0 }
uniform float u_reflection_amount;

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

  // swap y and z
  // reflectVec.xyz = reflectVec.xzy;

  // Convert to spheremap coords.
  reflectVec.z += 1.0;
  float m = 0.5 * inversesqrt( dot(reflectVec, reflectVec) );
  vec2 sphereCoords = reflectVec.xy * m + 0.5;
  // sphereCoords.y = -sphereCoords.y;
  
  float reflectionAmount = u_reflection_amount * gloss;
  vec3 reflectColor = texture(reflection_tex, sphereCoords).rgb;
  reflectColor = pow(reflectColor, vec3(2.2, 2.2, 2.2));

  fragColor.rgb = mix(fragColor.rgb, reflectColor.rgb, reflectionAmount);

  // albedoOutput(fragColor);
  // diffuseShadingOutput(fragColor); 
  return vec4(fragColor, 1);
}