#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float maxcomp(vec2 p) {
  return max(p.x, p.y);
}

float sdBox(vec3 p, vec3 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdBox(vec2 p, vec2 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

/*
float sdCross(vec3 p) {
  float da = sdBox(p.xy, vec2(1.0));
  float db = sdBox(p.yz, vec2(1.0));
  float dc = sdBox(p.zx, vec2(1.0));
  return min(da, min(db, dc));
}
*/

float sdCross(vec3 p) {
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.xz));
  return min(da, min(db, dc)) - 1.0;
}


mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float map(vec3 p) {
  p.zx *= rotate(time);
  p.yx *= rotate(time * 0.5);

  /**
  float d = sdBox(p, vec3(1.0));
  float s = 1.0;
  for (int m = 0; m < 1; m++) {
    vec3 a = mod(p * s, 2.0) - 1.0;
    s *= 3.0;
    vec3 r = abs(1.0 - 3.0 * abs(a));

    float da = max(r.x, r.y);
    float db = max(r.y, r.z);
    float dc = max(r.z, r.x);
    float c = (min(da, min(db, dc)) - 1.0) / s;
    d = max(d, c);
  }
  return d;
  */

  float d = sdBox(p, vec3(1.0));
  float s = 1.0;
  for (int m = 0; m < 4; m++) {
    vec3 a = mod(p * s, 2.0) - 1.0;
    s *= 3.0;
    vec3 r = 1.0 - 3.0 * abs(a);
    float c = sdCross(r) / s;
    d = max(d, c);
  }
  return d;


  /*
  float d = sdBox(p, vec3(1.0));
  float c = sdCross(p * 3.0) / 3.0;
  d = max(d, -c);
  return d;
  */
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
  for (int i = 0; i < 64; i++) {
    float d = map(p);
    p += d * rd;
    if (d < 0.01) {
      vec3 n = normal(p);
      return n * 0.5 + 0.5;
      //return vec3(0.1) + vec3(0.95, 0.5, 0.5) * max(0.0, dot(n, normalize(vec3(1.0))));
    }
  }
  return vec3(1.0);
}

void main( void ) {

  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 ta = vec3(0.0);
  vec3 z = normalize(ta - ro);
  vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
  vec3 y = normalize(cross(x, z));
  vec3 rd = normalize(st.x * x + st.y * y + 1.5 * z);

  vec3 c = raymarch(ro, rd);

  gl_FragColor = vec4(c, 1.0);
}