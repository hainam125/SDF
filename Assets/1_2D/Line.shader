//https://iquilezles.org/articles/distfunctions2d/
Shader "Unlit/Line"
{
    Properties
    {
        _Color ("Color", color) = (1,1,1,1)
        _Points ("Points", vector) = (0,0,0,0)
        _Thickness ("Thickness", float) = 0.5
        _Crispness ("Crispness", float) = 0.1
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

            float lineSegment(float2 p, float2 a, float2 b) {
                float2 ba = b - a;
                float2 pa = p - a;
                float k = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * k);
            }

            fixed drawLine(float2 p) {
                return smoothstep(_Thickness + _Crispness, _Thickness, lineSegment(p, _Points.xy, _Points.zw));
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
                float2 p = (i.uv - 0.5) * 2;
                return drawLine(p) * _Color;
            }
            ENDCG
        }
    }
}
