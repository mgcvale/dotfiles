// This is a little less performant than noise.frag
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float dotPattern(vec2 st) {
    float n = noise(st * 1500.0); // This is the density
    return smoothstep(0.4, 0.5, n);
}

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    
    float grain = dotPattern(v_texcoord) * 0.02; // This is the intensity
    
    color.rgb = color.rgb + (grain - 0.01); // 0.01 for brightness correction
    
    gl_FragColor = color;
}
