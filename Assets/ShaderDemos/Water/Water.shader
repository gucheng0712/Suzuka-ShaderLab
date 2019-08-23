Shader "Suzuka-ShaderLab/Water"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_ShallowColor("Shallow Water Color",Color) = (1,1,1,1)
		_DeepColor("Deep Water Color",Color) = (1,1,1,1)
		_DeepRange("Deep Water Range",Range(0.1,50)) = 1
		_Transparency("Transparency",Range(0,100)) = 0.5
		_NormalTex("Normal Map",2D) = "bump"{}
		_NormalIntensity("Normal Intensity",Range(0,2)) = 1
		_Resolution("Resolution",Range(0,10)) = 0.5
		_FlowSpeed("Water Flow Speed",float) = 1

		_Specular("Specular",Range(0.1,10)) = 1
		_Gloss("Gloss", Range(0,10)) = 0.5
		_SpecularColor("SpecularColor",Color) = (1,1,1,1)

		_WaveTex("Wave Map", 2D) = "white"{}
		_NoiseTex("Noise Map",2D) = "white"{}
		_WaveSpeed("Wave Speed",float) = 1
		_WaveOffset("Wave Offset",float) = 0.5
		_WaveRange("Wave Range", float)=0.5
		_WaveDelta("WaveDelta",float) = 0.5
		_Distortion("Distortion",float) =0.5
		_Cubemap("Cubemap",Cube) = "_Skybox"{}
		_FresnelScale("Fresnel Scale",Range(0,1)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent"  "Queue" = "Transparent"  }
		LOD 200

		GrabPass{"_GrabTex"}
	

		ZWrite Off
		CGPROGRAM
		#pragma surface surf WaterLightModel vertex:vert alpha noshadow
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _WaveTex;
		sampler2D _NoiseTex;
		sampler2D _GrabTex;
		float4 _GrabTex_TexelSize;
		sampler2D_float _CameraDepthTexture;
		samplerCUBE _Cubemap;

		fixed4 _Color;
		fixed4 _ShallowColor;
		fixed4 _DeepColor;
		half _DeepRange;
		half _Transparency;

		half _FlowSpeed;
		half _Resolution;
		half _NormalIntensity;

		half _Specular;
		half _Gloss;
		fixed4 _SpecularColor;

		float _WaveSpeed;
		float _WaveOffset;
		float _WaveRange;
		float _WaveDelta;

		float _Distortion;

		float _FresnelScale;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_NormalTex;
			float2 uv_WaveTex;
			float2 uv_NoiseTex;
			float4 proj;
			float3 worldRefl;
			float3 worldNormal;
			INTERNAL_DATA
			float3 viewDir;
		};


		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
		// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)


		fixed4 LightingWaterLightModel(SurfaceOutput s, fixed3 lightDir, half3 viewDir,fixed atten) 
		{
			float3 diffuse = max(0, dot(normalize(lightDir), s.Normal))*s.Albedo*_LightColor0.rgb;
			half3 halfDir = normalize(lightDir + viewDir);
			float HdotN = max(0, dot(halfDir, s.Normal));
			float3 specular = pow(HdotN, s.Specular * 128)*s.Gloss*_SpecularColor.rgb * _LightColor0.rgb;
			fixed4 col;
			col.rgb = diffuse + specular;
			col.a = s.Alpha + specular;
			return col;
		}
		void vert(inout appdata_full v, out Input i)
		{
			UNITY_INITIALIZE_OUTPUT(Input, i);
			//计算屏幕空间坐标
			i.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
			COMPUTE_EYEDEPTH(i.proj.z);
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			// tex2Dproj(_CameraDepthTexture,IN.proj)=tex2D(_CameraDepthTexture,IN.proj.xy/IN.proj.w)
			// 同时也有一个内置的宏
			// SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,IN.proj).r;
			half depth = tex2Dproj(_CameraDepthTexture, IN.proj).r;
			depth = LinearEyeDepth(depth); //把深度纹理的采样结果转换到视角空间下的深度值
			half deltaDepth = depth - IN.proj.z;
			fixed4 c = lerp(_ShallowColor, _DeepColor,  min(deltaDepth,_DeepRange)/ _DeepRange);

			// Normal
			float4 normalOffset1 = tex2D(_NormalTex, IN.uv_NormalTex + float2(_FlowSpeed*_Time.x, 0));
			float4 normalOffset2 = tex2D(_NormalTex, float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x) + float2(_FlowSpeed*_Time.x, 0));

			float4 normalOffset = (normalOffset1 + normalOffset2) / 2;
			float2 uvOffset = UnpackNormal(normalOffset).xy*_Resolution;

			float4 normal1 = tex2D(_NormalTex, IN.uv_NormalTex + uvOffset + float2(_FlowSpeed*_Time.x, 0));
			float4 normal2 = tex2D(_NormalTex, float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x)
				+ uvOffset + float2(_FlowSpeed*_Time.x, 0));

			float3 normal = UnpackNormal((normal1 + normal2) / 2).xyz;

			// 波浪
			half wave = 1- min(_WaveRange, deltaDepth) / _WaveRange;
			fixed4 noiseSampler = tex2D(_NoiseTex, IN.uv_NoiseTex);
			fixed4 waveSamplerA = tex2D(_WaveTex, float2(wave + _WaveOffset * sin(_Time.x*_WaveSpeed + noiseSampler.r), 1) + uvOffset);
			waveSamplerA.rgb *= (1 - (sin(_Time.x*_WaveSpeed + noiseSampler.r) + 1) / 2)*noiseSampler.r;
			fixed4 waveSamplerB = tex2D(_WaveTex, float2(wave + _WaveOffset * sin(_Time.x*_WaveSpeed +_WaveDelta+ noiseSampler.r), 1) + uvOffset);
			waveSamplerB.rgb *= (1 - (sin(_Time.x*_WaveSpeed + _WaveDelta+ noiseSampler.r) + 1) / 2)*noiseSampler.r;
			fixed4 waveColor = waveSamplerA + waveSamplerB;

			// GrabTexture
			float2 offset = normal.xy*_Distortion * _GrabTex_TexelSize.xy;
			IN.proj.xy = offset * IN.proj.z + IN.proj.xy;
			fixed3 refraction = tex2D(_GrabTex, IN.proj.xy / IN.proj.w).rgb;

			// Cubemap
			fixed3 reflection = texCUBE(_Cubemap,WorldReflectionVector(IN,normal)).rgb;
			fixed fresnel = _FresnelScale + (1 - _FresnelScale)*pow(1 - dot(IN.viewDir, WorldNormalVector(IN,normal)), 5);

			fixed3 refraToRefl = lerp( reflection, refraction, saturate(fresnel));

			o.Albedo = refraToRefl *(c.rgb + waveColor * wave);


			o.Normal =normal;
			o.Normal.xy *= _NormalIntensity;
			o.Gloss = _Gloss;
			o.Specular = _Specular;
			o.Alpha = min(_Transparency,deltaDepth)/_Transparency;
		}
			ENDCG
	}
	FallBack "Diffuse"
}
