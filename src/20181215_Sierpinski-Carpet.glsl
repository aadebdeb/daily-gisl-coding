// Sierpinski Carpet
// by @aa_debdeb (https://twitter.com/aa_debdeb)

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float box(vec2 p, vec2 s) {
	p = abs(p) - s;
	return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float sierpinskiCarpet(vec2 p) {
	
	float s = 1.0;
	float f  = 1.0 / 3.0;
	float d = box(p, vec2(s));
	for (int i = 0; i < 4; i++) {
		d = max(d, -box(p, vec2(f)) / s);
		p = abs(p);
		p -= f;
		p = abs(p);
		p -= f;
		p *= 3.0;
		s *= 3.0;
	}
	return d;	
}

void main( void ) {

	vec2 p = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
	
	float d = sierpinskiCarpet(p * 1.3);
	
	vec3 c = d > 0.0 ? vec3(0.0) : vec3(1.0);
	
	gl_FragColor = vec4(c, 1.0);

}