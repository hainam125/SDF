Shader "Unlit/Clock"
{
    Properties
    {
        _Color ("Color", color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _Color;
            float4 _Points;
            float _Thickness;
            float _Crispness;

            float smt(float value, float thickness) {
                return smoothstep(thickness + 0.02, thickness, value);
            }

            float lineSegment(float2 p, float2 a, float2 b) {
                float2 ba = b - a;
                float2 pa = p - a;
                float k = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * k);
            }

            float drawLine(float2 p, float2 a, float2 b, float thickness) {
                return smt(lineSegment(p, a, b), thickness);
            }

            float2 rotate(float2 v, float angle) {
                float cosA = cos(angle);
                float sinA = sin(angle);
                return float2(cosA * v.x - sinA * v.y, sinA * v.x + cosA * v.y);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                const float pi = 3.14159265359;
                float2 p = (i.uv - 0.5) * 2;
                float arm = max(
                    drawLine(p, float2(0, 0), rotate(float2(0.65, 0), -_Time.y / pi), 0.03),
                    drawLine(p, float2(0, 0), rotate(float2(0.5, 0), -_Time.y / 60 / pi), 0.04)
                );
                float dist = length(p);
                float center = max(smt(dist, 0.1),arm);

                float numberGuides = smoothstep(0.9, 1, cos(atan2(p.y, p.x) * 12));
                float numbersMask = smt(dist, 0.9)- smt(dist, 0.75);
                float numbers = numberGuides * numbersMask;
                return max(numbers, center);
            }
            ENDCG
        }
    }
}
