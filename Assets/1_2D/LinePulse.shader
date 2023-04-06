Shader "Unlit/LinePulse"
{
    Properties
    {
        _LineColor("Line Color", color) = (1,1,1,1)
        _Step("Step", float) = 1
        _Freq("Frequencey", float) = 1
        _HueStep("Hue Step", float) = 1
        _Saturation("Saturation", float) = 0.5
        _Value("Value", float) = 1
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

            float3 RGBToHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 HSVToRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            float lineSegment(float2 p, float2 a, float2 b) {
                float2 ba = b - a;
                float2 pa = p - a;
                float k = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * k);
            }

            float3 _LineColor;
            float _Step;
            float _Freq;
            float _HueStep;
            float _Saturation;
            float _Value;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 p = (i.uv - 0.5) * 2;
                float ls = lineSegment(p, float2(-0.25,0),float2(0.25,0))*_Step - _Freq*_Time.y;
                float3 color = HSVToRGB(float3((floor(ls) / _HueStep) % 1, _Saturation, _Value));
                return float4(lerp(color, _LineColor, cos(ls)),1);
            }
            ENDCG
        }
    }
}
