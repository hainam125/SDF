Shader "Unlit/Sphere"
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
            #define STEP_SIZE 0.01

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

            bool sphereHit(float3 p) {
                return distance(p, _Center) < _Radius;
            }

            bool raymarchHit(float3 position, float3 direction) {
                for (int i = 0; i < STEPS; i++) {
                    if (sphereHit(position)) return true;
                    position += direction * STEP_SIZE;
                }
                return false;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                float3 viewDirection = normalize(worldPosition - _WorldSpaceCameraPos);
                if (raymarchHit(worldPosition, viewDirection))
                    return fixed4(1,0,0,1); // Red if hit the ball
                else
                    return fixed4(1,1,1,1); // White otherwise
            }
            ENDCG
        }
    }
}
