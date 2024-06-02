Shader "Custom/VertexLitFaceShader"
{
    Properties
    {
        _FaceTexture ("Face Texture", 2D) = "white" {}

        _Color ("Specular Color", Color) = (0,0,0,0)
        _Emission ("Emissive Color", Color) = (0,0,0,0)

        [HideInInspector] _PupilTextureL ("Left Pupil Texture", 2D) = "white" {}
        [HideInInspector] _PupilTextureR ("Right Pupil Texture", 2D) = "white" {}

        [HideInInspector] _EyeTexture ("Eye Texture", 2D) = "white" {}
        [HideInInspector] _UVEyeScale ("Eye Texture Scaling Factor", float) = 0

        [HideInInspector] _MouthTexture ("Mouth Texture", 2D) = "white" {}
        [HideInInspector] _UVMouthScale ("Mouth Texture Scaling Factor", float) = 0

        [HideInInspector] _UVEyeOffset ("Eye Offset", Vector) = (0, 0, 0)
        [HideInInspector] _UVMouthOffset ("Mouth Offset", Vector) = (0, 0, 0)

        [HideInInspector] _UVPupilOffsetR ("Right Pupil Offset", Vector) = (0, 0, 0)
        [HideInInspector] _UVPupilOffsetL ("Left Pupil Offset", Vector) = (0, 0, 0)
        [HideInInspector] _UVPupilScale ("Pupil Texture Scaling Factor", float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        
        LOD 100
        
        Pass
        {
            Tags{ "LightMode" = "Vertex" }

            Lighting On
            CGPROGRAM

            // Pragmas
            #pragma vertex vert
            #pragma fragment frag

            // Fog support
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;          
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                UNITY_FOG_COORDS(6)
                float4 vertex : SV_POSITION;
                fixed4 diff : COLOR0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _FaceTexture;
            sampler2D _EyeTexture;
            sampler2D _PupilTextureL;
            sampler2D _PupilTextureR;
            sampler2D _MouthTexture;

            float _UVEyeScale;
            float _UVPupilScale;
            float _UVMouthScale;

            float2 _UVEyeOffset;
            float2 _UVMouthOffset;
            float2 _UVPupilOffsetR;
            float2 _UVPupilOffsetL;

            float4 _Color;
            fixed4 _Emission;

            v2f vert (appdata v)
            {
                v2f o;
     
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv0 = v.uv0;                                                                                      // Base texture uvs
                o.uv1 = (((v.uv1 - float2(0, 1)) * _UVEyeScale) + float2(0, 1)) + _UVEyeOffset;                     // Eye texture uvs
                o.uv2 = (((v.uv2 - float2(0.5, 0.5)) * (1 / _UVPupilScale)) + float2(0.5, 0.5)) + _UVPupilOffsetL;  // L Pupil
                o.uv3 = (((v.uv3 - float2(0.5, 0.5)) * (1 / _UVPupilScale)) + float2(0.5, 0.5)) + _UVPupilOffsetR;  // R Pupil
                o.uv4 = (((v.uv4 - float2(0, 1)) * _UVMouthScale) + float2(0, 1)) + _UVMouthOffset;                 // Mouth texture uvs

                float4 lighting = float4(ShadeVertexLightsFull(v.vertex, v.normal, 4, true), 1);
                o.diff = lighting * _Color;

                UNITY_TRANSFER_FOG(o,o.vertex); // Pass fog

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 faceColor = tex2D(_FaceTexture, i.uv0);
                fixed4 eyeColor = tex2D(_EyeTexture, i.uv1);
                fixed4 mouthColor = tex2D(_MouthTexture, i.uv4);

                fixed4 pupilColorL = tex2D(_PupilTextureL, i.uv2);
                fixed4 pupilColorR = tex2D(_PupilTextureR, i.uv3);

                fixed4 pupilsColor = (eyeColor * pupilColorL) * (eyeColor * pupilColorR);

                fixed4 finalColorE = lerp(faceColor, pupilsColor, eyeColor.a);
                fixed4 finalColorM = lerp(finalColorE, mouthColor, mouthColor.a);

                // Lighting
                fixed4 diffColor = finalColorM;
                diffColor.xyz = diffColor.xyz * i.diff.xyz;
                diffColor.w = diffColor.w * i.diff.w;

                finalColorM = lerp(diffColor, finalColorM, _Emission);

                // Apply fog
                UNITY_APPLY_FOG(i.fogCoord, finalColorM);

                return finalColorM;
            }
            ENDCG
        }

        // Pass to render object as a shadow caster
        Pass 
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // Allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"

            struct v2f 
            {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert( appdata_base v )
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
}