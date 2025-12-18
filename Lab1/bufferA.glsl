void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // используем ТОЛЬКО пиксель (0,0) как память
    if (fragCoord.x > 1.0 || fragCoord.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    // читаем прошлое состояние КОРРЕКТНО
    float carX = texelFetch(iChannel1, ivec2(0, 0), 0).r;

    // клавиатура
    float left  = texture(iChannel0, vec2(37.0/256.0, 0.0)).r;
    float right = texture(iChannel0, vec2(39.0/256.0, 0.0)).r;

    // движение
    float speed = 1.0;
    float dt = iTimeDelta;

    carX += (right - left) * speed * dt;

    // границы экрана
    carX = clamp(carX, -0.8, 0.8);

    fragColor = vec4(carX, 0.0, 0.0, 1.0);
}
