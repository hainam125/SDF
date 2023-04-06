Shader "Unlit/Raymarching"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Radius("Radius", float) = 0.5
        _Center("Center", Vector) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define STEPS 64
            #define MIN_DISTANCE 0.01

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 wPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Radius;
            float3 _Center;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float sphereDistance(float3 p) {
                return distance(p, _Center) - _Radius;
            }

            fixed4 raymarch(float3 position, float3 direction) {
                for (int i = 0; i < STEPS; i++)
                {
                    float distance = sphereDistance(position);
                    if (distance < MIN_DISTANCE) return i / (float)STEPS;
                    position += distance * direction;
                }
                return 0;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                float3 viewDirection = normalize(worldPosition - _WorldSpaceCameraPos);
                return raymarch(worldPosition, viewDirection);
            }
            ENDCG
        }
    }
}
