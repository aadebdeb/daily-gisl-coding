float diffuseLambert(float dotNL) {
    return max(0.0, dotNL) * INV_PI;
}

float specularBlinnPhongNormalized(float dotNH, float m) {
    float n = (m + 2.0) / TAU;
    return n * pow(max(0.0, dotNH), m);
}