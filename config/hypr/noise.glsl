#version 450

layout(location = 0) out vec4 fragColor;
layout(location = 0) in vec2 fragCoord;
layout(push_constant) uniform PushConstants {
    float time;
};

float random(vec2 uv) {
    return fract(sin(dot(uv.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
    vec2 uv = fragCoord.xy / vec2(1920.0, 1080.0); // Adjust for your screen resolution
    float noise = random(uv + vec2(time * 0.1, time * 0.1));
    fragColor = mix(vec4(1.0), vec4(noise, noise, noise, 1.0), 0.05); // Adjust 0.05 for noise strength
}

