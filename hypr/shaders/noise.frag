precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
// Improved hash function
float hash(vec2 p) {
    vec2 k = vec2(23.14069263277926, 2.665144142690225);
    float h = dot(p, k);
    return fract(cos(h) * 12345.6789);
}
// Modified dot pattern that avoids dark bands
float dotPattern(vec2 st) {
    // Scale coordinates differently to avoid banding
    vec2 noisePos = st + vec2(sin(st.y * 2.7) * 0.1, cos(st.x * 3.2) * 0.2);
    
    // Adjusted scale to maintain noise size but break up banding
    vec2 i = floor(noisePos * vec2(2500.0, 1597.0));
    
    float v = hash(i);
    
    // Simplified smoothstep with adjusted range
        return smoothstep(0.7, 0.9, v) * 0.035;
}

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    color.rgb += dotPattern(v_texcoord) - 0.004;
    gl_FragColor = color;
}
