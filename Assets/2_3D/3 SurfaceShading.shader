Shader "Unlit/SurfaceShading"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Radius("Radius", float) = 0.5
        _Center("Center", Vector) = (0,0,0,1)
        _Color("Color", Color) = (1,1,1,1)
        _SpecularPower("Specular Power", float) = 0.5
        _Gloss("Gloss", float) = 0.5
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
            #include "Lighting.cginc"

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
            float3 _Color;
            float _SpecularPower;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 simpleLambert(fixed3 normal, float3 viewDirection) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                fixed3 lightCol = _LightColor0.rgb;
                fixed NdotL = max(dot(normal, lightDir), 0);
                fixed4 c;
                // Specular
                fixed3 h = (lightDir - viewDirection) / 2.;
                fixed s = pow(dot(normal, h), _SpecularPower) * _Gloss;
                c.rgb = _Color * lightCol * NdotL + s;
                c.a = 1;
                return c;
            }

            float map(float3 p) {
                return distance(p, _Center) - _Radius;
            }

            float3 normal(float3 p) {
                const float eps = 0.01;

                return normalize(
                    float3(
                        map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
                    )
                );
            }

            fixed4 renderSurface(float3 p, float3 viewDirection) {
                float3 n = normal(p);
                return simpleLambert(n, viewDirection);
            }

            fixed4 raymarch(float3 position, float3 direction) {
                for (int i = 0; i < STEPS; i++)
                {
                    float distance = map(position);
                    if (distance < MIN_DISTANCE) return renderSurface(position, direction);
                    position += distance * direction;
                }
                return 1;
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
