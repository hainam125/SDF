Shader "Hidden/raymarching"
{
    Properties
    {
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "sdf.cginc"
            #include "test_normal.cginc"
            #include "sdf_metaball.cginc"
            #include "test_metaball.cginc"

            // Provided by our script
            uniform float3 _LightDir;
            uniform float3 _CameraWS;
            uniform float4x4 _FrustumCornersES;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_TexelSize;
            uniform float4x4 _CameraInvViewMatrix;
            uniform float4x4 _MatTorus_InvModel;

            uniform sampler2D _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;

                // Index passed via custom blit function in RaymarchGeneric.cs
                half index = v.vertex.z;
                v.vertex.z = 0.1;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;

#if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                    o.uv.y = 1 - o.uv.y;
#endif

                // Get the eyespace view ray (normalized)
                o.ray = _FrustumCornersES[(int)index].xyz;

                // Dividing by z "normalizes" it in the z axis
                // Therefore multiplying the ray by some number i gives the viewspace position
                // of the point on the ray with [viewspace z]=i
                o.ray /= abs(o.ray.z);

                // Transform the ray from eyespace to worldspace
                // Note: _CameraInvViewMatrix was provided by the script
                o.ray = mul(_CameraInvViewMatrix, o.ray);
                return o;
            }


            // This is the distance field function.  The distance field represents the closest distance to the surface
            // of any object we put in the scene.  If the given point (point p) is inside of an object, we return a
            // negative answer.
            float map(float3 p) {
                //return test1(p, _MatTorus_InvModel);
                //return test3(p);
                return testMetalballs(p);
            }

            float3 calcNormal(in float3 pos)
            {
                // epsilon - used to approximate dx when taking the derivative
                const float2 eps = float2(0.001, 0.0);

                // The idea here is to find the "gradient" of the distance field at pos
                // Remember, the distance field is not boolean - even if you are inside an object
                // the number is negative, so this calculation still works.
                // Essentially you are approximating the derivative of the distance field at this point.
                float3 nor = float3(
                    map(pos + eps.xyy).x - map(pos - eps.xyy).x,
                    map(pos + eps.yxy).x - map(pos - eps.yxy).x,
                    map(pos + eps.yyx).x - map(pos - eps.yyx).x);
                return normalize(nor);
            }

            // Raymarch along given ray
            // ro: ray origin
            // rd: ray direction
            fixed4 raymarch(float3 ro, float3 rd, float s) {
                const float drawdist = 40; // draw distance in unity units
                const int maxstep = 64;

                fixed4 ret = fixed4(0, 0, 0, 0);
                float t = 0; // current distance traveled along ray
                for (int i = 0; i < maxstep; ++i) {
                    // If we run past the depth buffer, stop and return nothing (transparent pixel)
                    // this way raymarched objects and traditional meshes can coexist.
                    if (t >= s || t > drawdist) {
                        ret = fixed4(0, 0, 0, 0);
                        break;
                    }

                    float3 p = ro + rd * t; // World space position of sample
                    float d = map(p);       // Sample of distance field (see map())

                    // If the sample <= 0, we have hit something (see map()).
                    if (d < 0.001) {
                        // Lambertian Lighting
                        float3 n = calcNormal(p);
                        float ptg = (float)i / maxstep;
                        float4 perf = float4(ptg, ptg, ptg, 1);
                        float4 light = fixed4(dot(-_LightDir.xyz, n).rrr, 1);
                        ret = light;
                        break;
                    }

                    // If the sample > 0, we haven't hit anything yet so we should march forward
                    // We step forward by distance d, because d is the minimum distance possible to intersect
                    // an object (see map()).
                    t += d;
                }

                return ret;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ray direction
                float3 rd = normalize(i.ray.xyz);
                // ray origin (camera position)
                float3 ro = _CameraWS;

                float2 duv = i.uv;
                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                    duv.y = 1 - duv.y;
                #endif

                // Convert from depth buffer (eye space) to true distance from camera
                // This is done by multiplying the eyespace depth by the length of the "z-normalized"
                // ray (see vert()).  Think of similar triangles: the view-space z-distance between a point
                // and the camera is proportional to the absolute distance.
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, duv).r);
                depth *= length(i.ray.xyz);

                fixed3 col = tex2D(_MainTex,i.uv);
                fixed4 add = raymarch(ro, rd, depth);

                // Returns final color using alpha blending
                return fixed4(col * (1.0 - add.w) + add.xyz * add.w,1.0);
            }
            ENDCG
        }
    }
}
