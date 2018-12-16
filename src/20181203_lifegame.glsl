// Life Game
//
// by @aa_debdeb (https://twitter.com/aa_debdeb)
// 2018/12/03

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backBuffer;

float random(vec2 x) {
   	return fract(sin(dot(x ,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void ) {
	
	float d = length(2.0 * (gl_FragCoord.xy - mouse * resolution) / min(resolution.x, resolution.y));
	bool nextState = false;
	if (d < 0.1) {
		nextState = random(gl_FragCoord.xy * 0.32 + time * vec2(34.34, 24.43)) < 0.3;
	} else {
		float center = texture2D(backBuffer, gl_FragCoord.xy / resolution).w;
		
		int neighbor =  int(texture2D(backBuffer, (gl_FragCoord.xy + vec2(-1.0, 1.0)) / resolution).w
			+  texture2D(backBuffer, (gl_FragCoord.xy + vec2(0.0, 1.0)) / resolution).w
			+ texture2D(backBuffer, (gl_FragCoord.xy + vec2(1.0, 1.0)) / resolution).w
			+  texture2D(backBuffer, (gl_FragCoord.xy + vec2(-1.0, 0.0)) / resolution).w
			+ texture2D(backBuffer, (gl_FragCoord.xy + vec2(1.0, 0.0)) / resolution).w
			+ texture2D(backBuffer, (gl_FragCoord.xy + vec2(-1.0, -1.0)) / resolution).w
			+ texture2D(backBuffer, (gl_FragCoord.xy + vec2(0.0, -1.0)) / resolution).w
			+  texture2D(backBuffer, (gl_FragCoord.xy + vec2(1.0, -1.0)) / resolution).w);
		
		bool alive = center > 0.5;
		nextState = (alive && (neighbor == 2 || neighbor == 3)) || (!alive && neighbor == 3);
	}

	vec3 c = nextState ? vec3(0.15, 0.35, 0.35) : vec3(0.95);
	
	gl_FragColor = vec4(c, nextState ? 1.0 : 0.01);	

}