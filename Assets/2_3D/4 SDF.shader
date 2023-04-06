Shader "Unlit/SurfaceShading"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
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
            #define MIN_DISTANCE 0.001

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

            float sdf_sphere(float3 p, float3 c, float r)
            {
                return distance(p, c) - r;
            }

            float sdf_box(float3 p, float3 c, float3 s)
            {
                float x = max(
                    p.x - c.x - float3(s.x / 2., 0, 0),
                    c.x - p.x - float3(s.x / 2., 0, 0)
                );

                float y = max(
                    p.y - c.y - float3(s.y / 2., 0, 0),
                    c.y - p.y - float3(s.y / 2., 0, 0)
                );

                float z = max(
                    p.z - c.z - float3(s.z / 2., 0, 0),
                    c.z - p.z - float3(s.z / 2., 0, 0)
                );

                float d = x;
                d = max(d, y);
                d = max(d, z);
                return d;
            }

            float sdf_blend(float d1, float d2, float a) {
                return a * d1 + (1 - a) * d2;
            }

            float sdf_smin(float a, float b, float k = 32) {
                float res = exp(-k * a) + exp(-k * b);
                return -log(max(0.0001, res)) / k;
            }

            float testBlend(float3 p) {
                float r = 0.5;
                return sdf_blend
                (
                    sdf_sphere(p, 0, r),
                    sdf_box(p, 0, r),
                    (_SinTime[3] + 1.) / 2.
                );
            }

            float testUnion(float3 p) {
                return min
                (
                    sdf_sphere(p, -float3 (0.5, 0, 0), 0.6), // Left sphere
                    sdf_sphere(p, +float3 (0.5, 0, 0), 0.6)  // Right sphere
                );
            }

            float testMinus(float3 p) {
                float r = 1;
                return max(-sdf_sphere(p, 0, r*0.6), sdf_box(p, 0, r));
            }

            float map(float3 p) {
                return testMinus(p);
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
