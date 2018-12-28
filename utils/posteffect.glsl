float convertToGreyscale(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}