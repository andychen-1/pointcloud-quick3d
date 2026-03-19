VARYING vec3 vColor;

void MAIN() {
    vColor = COLOR.rgb;
    gl_PointSize = clamp(2.0, 1.0, 64.0);
    POSITION = MODELVIEWPROJECTION_MATRIX * vec4(VERTEX, 1.0);
}
