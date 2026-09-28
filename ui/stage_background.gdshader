shader_type canvas_item;

// 0 is the quiet end of the current world. 1 is its vivid end.
uniform float mood : hint_range(0.0, 1.0) = 0.7;
uniform vec3 sky_top : source_color = vec3(0.02, 0.0, 0.04);
uniform vec3 sky_bottom : source_color = vec3(0.05, 0.0, 0.08);
uniform vec3 glow_color : source_color = vec3(0.55, 0.12, 0.75);
uniform int world = 2;

void fragment() {
	vec3 sky = mix(sky_top, sky_bottom, smoothstep(0.12, 0.92, UV.y));
	float top = smoothstep(0.42, 0.0, UV.y);
	float bottom = smoothstep(0.58, 1.0, UV.y);
	float side = max(smoothstep(0.18, 0.0, UV.x), smoothstep(0.82, 1.0, UV.x));
	float fringe = max(max(top * 0.85, bottom * 0.7), side);
	// The well covers the middle, so this sky only shows in the open margins.
	vec3 color = sky * 0.62 + glow_color * fringe * 0.5;
	// 0 desert, 1 water, 2 night. The playfield stays dark; this moves in the open margins.
	if (world == 0) {
		vec2 sand_uv = UV * vec2(48.0, 24.0) + vec2(TIME * 4.5, TIME * 0.65);
		float grain = fract(sin(dot(floor(sand_uv), vec2(127.1, 311.7))) * 43758.5453);
		float speck = smoothstep(0.972, 0.995, grain);
		float dune = smoothstep(0.32, 1.0, UV.y);
		color += vec3(1.0, 0.7, 0.28) * speck * dune * 0.75;
	} else if (world == 1) {
		float swell = 0.5 + 0.5 * sin(UV.y * 3.4 - TIME * 0.4);
		color += glow_color * swell * 0.06;
	} else if (world == 3) {
		float fire = 0.5 + 0.5 * sin(UV.x * 16.0 + TIME * 1.3);
		color += glow_color * fire * 0.09 * max(top, side);
	} else if (world == 4) {
		float heat = 0.5 + 0.5 * sin(UV.x * 20.0 + TIME * 2.1);
		color += vec3(1.0, 0.28, 0.06) * heat * 0.12 * bottom;
	} else if (world == 5) {
		vec2 rain_uv = vec2(UV.x * 36.0 + sin(TIME * 0.15) * 0.4, UV.y * 14.0 - TIME * 1.15);
		float column = fract(rain_uv.x);
		float drop = fract(rain_uv.y + fract(sin(floor(rain_uv.x) * 91.7) * 43758.5));
		float streak = smoothstep(0.0, 0.05, column) * smoothstep(0.14, 0.05, column);
		streak *= smoothstep(0.0, 0.12, drop) * smoothstep(0.42, 0.16, drop);
		float mist = 0.5 + 0.5 * sin(TIME * 0.22 + UV.y * 1.6);
		color += vec3(0.74, 0.82, 0.94) * streak * 0.28;
		color += glow_color * mist * 0.045;
	}
	color *= mix(0.55, 1.0, mood);
	COLOR = vec4(color, 1.0);
}
