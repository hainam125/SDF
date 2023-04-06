float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

// Torus
// t.x: diameter
// t.y: thickness
// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// Box
// b: size of box in x/y/z
// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) +
        length(max(d, 0.0));
}

// Union
// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opU(float d1, float d2)
{
    return min(d1, d2);
}

// Subtraction
// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opS(float d1, float d2)
{
    return max(-d1, d2);
}

// Intersection
// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opI(float d1, float d2)
{
    return max(d1, d2);
}