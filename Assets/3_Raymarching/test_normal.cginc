float test1(float3 p, float4x4 mat) {
    float4 q = mul(mat, float4(p, 1));
    return sdTorus(q, float2(1, 0.2));
}

float test2(float3 p) {
    float union_box = opU(
        sdBox(p - float3(-4.5, 0.5, 0), float3(1, 1, 1)),
        sdBox(p - float3(-3.5, -0.5, 0), float3(1, 1, 1))
    );
    float subtr_box = opS(
        sdBox(p - float3(-0.5, 0.5, 0), float3(1, 1, 1.01)),
        sdBox(p - float3(0.5, -0.5, 0), float3(1, 1, 1))
    );
    float insec_box = opI(
        sdBox(p - float3(3.5, 0.5, 0), float3(1, 1, 1)),
        sdBox(p - float3(4.5, -0.5, 0), float3(1, 1, 1))
    );

    float ret = opU(union_box, subtr_box);
    ret = opU(ret, insec_box);

    return ret;
}

float test3(float3 p) {
    float2 d_torus = float2(sdTorus(p, float2(1, 0.2)), 0.5);
    float2 d_box = float2(sdBox(p - float3(-3, 0, 0), float3(0.75, 0.5, 0.5)), 0.25);
    float2 d_sphere = float2(sdSphere(p - float3(3, 0, 0), 1), 0.75);

    float2 ret = opU(d_torus, d_box);
    ret = opU(ret, d_sphere);

    return ret;
}