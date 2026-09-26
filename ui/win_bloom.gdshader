shader_type canvas_item;

// 0 is a tight flash at the center. 1 is the ring after it has opened and faded.
uniform float spread : hint_range(0.0, 1.0) = 0.0;
uniform vec3 neon : source_color = vec3(1.0, 0.58, 0.98);

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 0.56;
	float d = length(p);
	float radius = mix(0.02, 0.62, spread);
	float ring = smoothstep(0.09, 0.0, abs(d - radius));
	float wash = smoothstep(radius + 0.22, 0.0, d);
	float life = 1.0 - smoothstep(0.5, 1.0, spread);
	COLOR = vec4(neon, (ring * 0.95 + wash * 0.4) * life);
}
