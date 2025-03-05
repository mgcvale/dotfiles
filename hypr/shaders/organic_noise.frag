// Save this as ~/.config/hypr/shaders/noise.frag

precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// Better random function for smoother dots
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Value noise for smoother pattern
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Mix the four corners
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

// Function to create dot pattern
float dotPattern(vec2 st) {
    float n = noise(st * 1500.0); // Increased frequency for smaller dots
    return smoothstep(0.4, 0.5, n); // Adjusted threshold for more defined dots
}

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    
    // Generate dot noise
    float grain = dotPattern(v_texcoord) * 0.02; // Adjust 0.02 for intensity
    
    // Apply the grain
    color.rgb = color.rgb + (grain - 0.01); // Slightly offset to maintain brightness
    
    gl_FragColor = color;
}
