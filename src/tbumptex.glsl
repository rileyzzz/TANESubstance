
//: param auto channel_basecolor 
uniform SamplerSparse basecolor_tex;

//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;

//: param auto channel_opacity
uniform SamplerSparse opacity_tex;

vec4 shade(V2F inputs) 
{
  vec3 color = getBaseColor(basecolor_tex, inputs.sparse_coord); 
  float specMask = textureSparse(specularlevel_tex, inputs.sparse_coord).r;
  float opacity = textureSparse(opacity_tex, inputs.sparse_coord).r;

  LightingOutput lighting = compute_tane_lighting(inputs);

  // diffuseShadingOutput(lighting.diffColor * color); 
  // specularShadingOutput(lighting.specColor * specMask); 
  vec3 fragColor = lighting.diffColor * color + lighting.specColor * specMask;

  // Blend in envmap.
  LocalVectors frame = computeLocalFrame(inputs);
  vec3 reflectVec = reflect(-frame.eye, frame.normal).xyz;

  // albedoOutput(fragColor);
  // diffuseShadingOutput(fragColor); 
  return vec4(fragColor, opacity);
}