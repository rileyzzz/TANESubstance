
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