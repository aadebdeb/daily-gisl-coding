// by @aa_debdeb (https://twitter.com/aa_debdeb)

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float map(vec3 p) {
  vec3 q = p;
  q.y = abs(p.y);
  q.y -= 2.0 * sin(floor(0.1 * q.z) * 1.0 - time * 8.0);
  q.y -= 2.0 * sin(floor(0.1 * q.x) * 1.0 - time * 8.0);  
  p.xz = mod(p.xz, 10.0) - 5.0;
  p = abs(p);
  return max(-(q.y - 5.0), max(p.x, p.z) - 3.0);
}

vec3 normal(vec3 p) {
  float d = 0.01;
  return normalize(vec3(
    map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
    map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
    map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
  ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
  vec3 p = ro;
  float minD = 9999.0;
  float sumD = 0.0;
  for (int i = 0; i < 128; i++) {
    float d = map(p);
    minD = min(minD, d);
    sumD += d;
    p += d * rd;
    if (d < 0.01) {
      float fog = exp(-pow(sumD * 0.008, 2.0));
      return 1.2 * vec3(0.8, 0.7, 1.0) * (1.0 - float(i) / float(128)) * fog;
    }

  }

  return vec3(0.0);
}

void main(void) {

  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  float camX = 55.0 * (mod(time, 10.0) < 5.0 ?
      mix(-1.0, 1.0, smoothstep(2.0, 3.0, mod(time, 5.0))) :
      mix(1.0, -1.0, smoothstep(2.0, 3.0, mod(time, 5.0))));
	
  vec3 ro = vec3(camX , 0.0,  -time * 30.0);
  vec3 ta = vec3(0.0, 0.0, -50.0 -time * 30.0);
  vec3 z = normalize(ta - ro);
  vec3 up = vec3(0.0, 1.0, 0.0);
  vec3 x = normalize(cross(z, up));
  vec3 y = normalize(cross(x, z));
  vec3 rd = normalize(st.x * x + st.y * y + 1.5 * z);

  vec3 c = raymarch(ro, rd);

  gl_FragColor = vec4(c, 1.0);
}