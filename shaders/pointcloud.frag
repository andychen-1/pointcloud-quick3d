VARYING vec3 vColor;

void MAIN() {
    mediump vec2 uv = gl_PointCoord * 2.0 - 1.0;
    mediump float d = dot(uv, uv);
    if (d > 1.0) discard;
    mediump float alpha = 1.0 - smoothstep(0.7, 1.0, d);
    FRAGCOLOR = vec4(vColor, alpha);
}
