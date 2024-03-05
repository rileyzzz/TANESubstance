cd src
for /F "tokens=*" %%A in (shaders.txt) do type lib-tane-lighting.glsl %%A > ../shelf/shaders/%%A