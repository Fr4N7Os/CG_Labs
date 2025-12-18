// =====================
// SDF primitives
// =====================

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// =====================
// Simple car (single SDF)
// =====================

float sdCar(vec2 p) {
    float body  = sdBox(p, vec2(0.20, 0.05));
    float cabin = sdBox(p - vec2(0.0, 0.07), vec2(0.10, 0.04));
    return min(body, cabin);
}

// =====================
// Random
// =====================

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// =====================
// Main
// =====================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    vec3 col = vec3(0.12, 0.13, 0.14);

    // =====================
    // Obstacles
    // =====================

    for (int i = 0; i < 6; i++) {

        float id = float(i);
        float speed = 0.4 + hash(id) * 0.5;

        float y = 1.2 - mod(iTime * speed + id * 2.0, 2.4);
        float x = hash(id * 10.0) * 1.6 - 0.8;

        float d = sdBox(uv - vec2(x, y), vec2(0.07));

        if (d < 0.0) {
            col = vec3(0.2, 0.85, 0.35);
        }
    }

    // =====================
    // Car (CORRECT READ)
    // =====================

    float carX = texelFetch(iChannel1, ivec2(0, 0), 0).r;
    vec2 carPos = vec2(carX, -0.75);

    float dCar = sdCar(uv - carPos);

    if (dCar < 0.0) {
        col = vec3(0.2, 0.6, 1.0);
    }

    fragColor = vec4(col, 1.0);
}
