
float random(vec2 p){
    return fract(sin(dot(p,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 p){
    return fract(sin(dot(p,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}