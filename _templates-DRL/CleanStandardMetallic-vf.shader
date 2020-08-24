// DRL: an intact version of very default PBR(metallic)-Standard surf-shader,
// which is only cleaned up from repeating code and properly formatted,
// but not affected in any way.
// Generated at: 2019.4.3f1
// Generated with:
// #pragma surface surf Standard fullforwardshadows exclude_path:deferred exclude_path:prepass noshadow noambient novertexlights nolightmap nofog nometa noforwardadd nolppv noshadowmask
Shader "DRL/CleanStandardMetallic (vert-frag)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	
	SubShader {
		
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		// ------------------------------------------------------------
		// Surface shader code generated out of a CGPROGRAM block:
		
		
		// ---- forward rendering base pass:
		Pass {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
				// #pragma target 3.0
				#pragma target 2.0
				
				// compile directives
				#pragma vertex vert_surf
				#pragma fragment frag_surf
				#pragma multi_compile_instancing
				#pragma multi_compile_fwdbase novertexlight noshadowmask nodynlightmap nolightmap noshadow
				#include "HLSLSupport.cginc"
				#define UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_LIGHTMAPSTS
				#include "UnityShaderVariables.cginc"
				#include "UnityShaderUtilities.cginc"

// DRL:
// Here, the generated shader variants should start. But their code is
// ___EXACTLY___ the same both when instancing is enabled or not
// (INSTANCING_ON is defined / not defined). So, only single code snippet below:

// Surface shader code generated based on:
// writes to per-pixel normal: no
// writes to emission: no
// writes to occlusion: no
// needs world space reflection vector: no
// needs world space normal vector: no
// needs screen space position: no
// needs world space position: no
// needs view direction: no
// needs world space view direction: no
// needs world space position for lighting: YES
// needs world space view direction for lighting: YES
// needs world space view direction for lightmaps: no
// needs vertex color: no
// needs VFACE: no
// passes tangent-to-world matrix to pixel shader: no
// reads from normal: no
// 1 texcoords actually used
//	 float2 _MainTex
// Stripping Light Probe Proxy Volume code because nolppv pragma is used. Using normal probe blending as fallback.

#include "UnityCG.cginc"

#undef UNITY_LIGHT_PROBE_PROXY_VOLUME
//Shader does not support lightmap thus we always want to fallback to SH.
#undef UNITY_SHOULD_SAMPLE_SH
#if (!defined(UNITY_PASS_FORWARDADD) && !defined(UNITY_PASS_PREPASSBASE) && !defined(UNITY_PASS_SHADOWCASTER) && !defined(UNITY_PASS_META))
	#define UNITY_SHOULD_SAMPLE_SH 1
#else
	#define UNITY_SHOULD_SAMPLE_SH 0
#endif

#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal

/* UNITY: Original start of shader */


// --------------------------------------------------------
// vertex-to-fragment interpolation data
// --------------------------------------------------------

	// DRL: the code is exactly the same when:
	// UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
	// is both defined or not. (half- and high-precision fragment shader registers)
	// And it's almost the same for:
	// * LIGHTMAP_ON
	// * UNITY_SHOULD_SAMPLE_SH
	// So it's more readable to combine it into a single conditional declaration:
	struct v2f_surf {
		UNITY_POSITION(pos);
		float2 pack0 : TEXCOORD0; // _MainTex
		float3 worldNormal : TEXCOORD1;
		float3 worldPos : TEXCOORD2;
		#ifdef LIGHTMAP_ON
			// DRL: with lightmaps:
			float4 lmap : TEXCOORD3;
		#elif UNITY_SHOULD_SAMPLE_SH
			// DRL: no lightmaps + do sample SH:
			half3 sh : TEXCOORD3; // SH
		#endif
		DECLARE_LIGHT_COORDS(4)
		UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
	};

// --------------------------------------------------------
// vertex shader
// --------------------------------------------------------

float4 _MainTex_ST;

v2f_surf vert_surf (appdata_full v) {
	UNITY_SETUP_INSTANCE_ID(v);
	
	v2f_surf o;
	UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
	UNITY_TRANSFER_INSTANCE_ID(v,o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	float3 worldNormal = UnityObjectToWorldNormal(v.normal);
	
	#if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
		fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
		fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
		fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
		#if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
			o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
			o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
			o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
		#endif
	#endif
	
	o.worldPos = worldPos;
	o.worldNormal = worldNormal;
	#ifdef LIGHTMAP_ON
		o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#else
		// !LIGHTMAP_ON
		// SH/ambient and vertex lights
		#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
			o.sh = 0;
			// Approximated illumination from non-important point lights
			#ifdef VERTEXLIGHT_ON
				o.sh += Shade4PointLights (
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, worldPos, worldNormal);
			#endif
			o.sh = ShadeSHPerVertex (worldNormal, o.sh);
		#endif
	#endif // !LIGHTMAP_ON
	
	COMPUTE_LIGHT_COORDS(o); // pass light cookie coordinates to pixel shader
	
	return o;
}

// --------------------------------------------------------
// surface function
// --------------------------------------------------------

// Original surface shader snippet:

// Physically based Standard lighting model, and enable shadows on all light types
//#pragma surface surf Standard fullforwardshadows exclude_path:deferred exclude_path:prepass noshadow noambient novertexlights nolightmap nofog nometa noforwardadd nolppv noshadowmask

sampler2D _MainTex;

struct Input {
	float2 uv_MainTex;
};

fixed3 _Color;
half _Metallic;
half _Smoothness;

void surf (Input IN, inout SurfaceOutputStandard o)
{
	// Albedo comes from a texture tinted by color
	fixed3 clr = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color;
	o.Albedo = clr;
	
	// Metallic and smoothness come from slider variables
	o.Metallic = _Metallic;
	o.Smoothness = _Smoothness;
	o.Alpha = 1.0;
}

// --------------------------------------------------------
// fragment shader
// --------------------------------------------------------

fixed4 frag_surf (v2f_surf IN) : SV_Target {
	UNITY_SETUP_INSTANCE_ID(IN);
	// prepare and unpack data
	Input surfIN;
	UNITY_INITIALIZE_OUTPUT(Input,surfIN);
	
	surfIN.uv_MainTex.x = 1.0;
	surfIN.uv_MainTex = IN.pack0.xy;
	float3 worldPos = IN.worldPos.xyz;
	#ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	#else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	#endif
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	
	// initialize surf structure with default values:
	#ifdef UNITY_COMPILER_HLSL
		SurfaceOutputStandard o = (SurfaceOutputStandard)0;
	#else
		SurfaceOutputStandard o;
	#endif
	o.Albedo = 0.0;
	o.Emission = 0.0;
	o.Alpha = 0.0;
	o.Occlusion = 1.0;
	fixed3 normalWorldVertex = fixed3(0,0,1);
	o.Normal = IN.worldNormal;
	normalWorldVertex = IN.worldNormal;
	
	// call surface function
	surf (surfIN, o);
	
	// compute lighting & shadowing factor
	UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
	fixed4 c = 0;
	
	// Setup lighting environment
	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.indirect.diffuse = 0;
	gi.indirect.specular = 0;
	gi.light.color = _LightColor0.rgb;
	gi.light.dir = lightDir;
	
	// Call GI (lightmaps/SH/reflections) lighting function
	UnityGIInput giInput;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
	giInput.light = gi.light;
	giInput.worldPos = worldPos;
	giInput.worldViewDir = worldViewDir;
	giInput.atten = atten;
	#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
		giInput.lightmapUV = IN.lmap;
	#else
		giInput.lightmapUV = 0.0;
	#endif
	#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
		giInput.ambient = IN.sh;
	#else
		giInput.ambient.rgb = 0.0;
	#endif
	giInput.probeHDR[0] = unity_SpecCube0_HDR;
	giInput.probeHDR[1] = unity_SpecCube1_HDR;
	#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
		giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
	#endif
	#ifdef UNITY_SPECCUBE_BOX_PROJECTION
		giInput.boxMax[0] = unity_SpecCube0_BoxMax;
		giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
		giInput.boxMax[1] = unity_SpecCube1_BoxMax;
		giInput.boxMin[1] = unity_SpecCube1_BoxMin;
		giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
	#endif
	
	LightingStandard_GI(o, giInput, gi);
	
	#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON)
		gi.indirect.diffuse = 0;
	#endif
	
	// realtime lighting: call lighting function
	c += LightingStandard (o, worldViewDir, gi);
	c.a = 1.0;
	return c;
}
			ENDCG
		
		}
		
		// ---- end of surface shader generated code
		
	}
	
	FallBack Off
	
}
