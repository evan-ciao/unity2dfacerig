Shader "Custom/FaceShader"
{
    Properties
    {
        _FaceTexture ("Face Texture", 2D) = "white" {}

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
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
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
                float4 vertex : SV_POSITION;
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv0;                                                                                      // Base texture uvs
                o.uv1 = (((v.uv1 - float2(0, 1)) * _UVEyeScale) + float2(0, 1)) + _UVEyeOffset;                     // Eye texture uvs
                o.uv2 = (((v.uv2 - float2(0.5, 0.5)) * (1 / _UVPupilScale)) + float2(0.5, 0.5)) + _UVPupilOffsetL;  // L Pupil
                o.uv3 = (((v.uv3 - float2(0.5, 0.5)) * (1 / _UVPupilScale)) + float2(0.5, 0.5)) + _UVPupilOffsetR;  // R Pupil
                o.uv4 = (((v.uv4 - float2(0, 1)) * _UVMouthScale) + float2(0, 1)) + _UVMouthOffset;                 // Mouth texture uvs
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
                return finalColorM;
            }
            ENDCG
        }
    }
}
