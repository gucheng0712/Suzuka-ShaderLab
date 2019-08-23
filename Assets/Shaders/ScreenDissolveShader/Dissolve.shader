// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UI/Dissolve"
{
    Properties {
        _MainTex("Main Texture",2D) = "white"{}
        _DissolveTex ("Dissolution Texture", 2D) = "gray" {}
        _DissolveScale ("DissolveScale", Range(0, 1)) = 0
    }
 
    SubShader {
 
        Tags { "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
 
        Pass {
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            sampler2D _DissolveTex;
            float _DissolveScale;
 
            struct v2f 
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
           

            v2f vert(appdata_base v) 
            {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.uv = v.texcoord;
                return f;
            }
 
            fixed4 frag(v2f f) : SV_Target 
            {
                float4 c = tex2D(_MainTex,f.uv);
                float val = tex2D(_DissolveTex, f.uv).r;
                
                c.a *= step(1.35 - _DissolveScale, val);
                return c;
            }
            ENDCG
        }
    }
}