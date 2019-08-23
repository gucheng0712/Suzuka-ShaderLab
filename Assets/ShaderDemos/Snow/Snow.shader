Shader "Envt/Snow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Base Color(RGB)",Color) = (0.5,0.5,0.5,1)
        _Ramp("Toon Ramp (RGB)",2D) = "white"{}
        _SnowRamp("Snow Toon Ramp (RGB)",2D) = "white"{}
        _SnowVector("Angle of Snow Buildup", Vector)=(0,1,0)
        _SnowColor("Snow Base Color (RGB)", Color) = (0.5,0.5,0.5,1)
        _TopColor("Snow Top Color (RGB)", Color) = (0.5,0.5,0.5,1)
        _RimColor("Snow Rim Color (RGB)", Color) = (0.5,0.5,0.5,1)
        _RimPower("Snow Rim Power", Range(0,4)) = 3
        _SnowSize("Snow Amount", Range(-2,2)) = 1
        _Height("Snow Height", Range(0,1)) = 0.1
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
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            float4 _Ramp_ST;
            sampler2D _SnowRamp;
            float4 _SnowRamp_ST;
            
            
            float4 _Color;
            float4 _SnowColor;
            float4 _TopColor;
            float4 _RimColor;
            
            float3 _SnowVector;
            
            float _RimPower;
            float _SnowSize;
            float _Height;
  

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                
            };
            

            v2f vert (appdata v)
            {   
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                // Snow direction convertion to worldspace
                float4 snowWorldDir = mul(_SnowVector,unity_ObjectToWorld);
                float snowCoverage = step(_SnowSize,dot(o.worldNormal,normalize(snowWorldDir)));
                
                // Using lerp instead of if statement for optimization
                v.vertex.xyz+= lerp(0,v.normal * _Height,snowCoverage);
                
                o.pos = UnityObjectToClipPos(v.vertex);
                 
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 lightDir = UnityWorldSpaceLightDir(i.pos);
               
                float NdotL = dot(i.worldNormal, lightDir)*0.5 + 0.5;
            
                fixed4 col = tex2D(_MainTex, i.uv)*_Color;
                half3 snowRamp = tex2D(_SnowRamp,float2(NdotL,NdotL)).rgb;
                
                half rim = 1-saturate(dot(normalize(i.viewDir),i.worldNormal));
                
                half snowCoverage = step(_SnowSize-0.2,dot(i.worldNormal,_SnowVector));
                
                float3 snowFinalColor = lerp(_SnowColor*snowRamp, _TopColor * snowRamp, 0.5)+_RimColor.rgb *pow(rim, _RimPower) ;
                
                // Using lerp instead of if statement for optimization
                float3 diffuse = lerp(col.rgb,snowFinalColor,snowCoverage);
                
                return fixed4(diffuse,1);
            }
            ENDCG
        }
    }
}
