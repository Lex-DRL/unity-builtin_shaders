Shader ".DRL-URP/Transparent" {
	Properties {
		_Color ("Color", Color) = (0.2, 0.6, 1, 1)
		[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		
		// _VectorParm ("Vector Parm", Vector) = (1, 1, 1, 0)
		// [PowerSlider(3.333333)] _RangeParm ("Range Parm", Range(0, 10)) = 1
		
		[Space] [Header(Shader Blending)]
		_TransparentShader ("Additive->Transparent", Range(0, 1)) = 1
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
		[Enum(Off, 0, On, 1)] _zWrite ("Z-Write", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _zTest ("Z-Test", Int) = 4
	}
	
	SubShader {
		Tags {
			// SRP:
			"RenderPipeline" = "UniversalPipeline"
			// "UniversalMaterialType" = "Lit"
				// https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@12.1/manual/urp-shaders/urp-shaderlab-pass-tags.html
				// Used only in Deferred:
				// * Lit - PBR (default, can be omitted)
				// * SimpleLit- BlinnPhong
			"ShaderModel"="2.0"
			
			// Legacy tags:
			// https://docs.unity3d.com/Manual/SL-SubShaderTags.html
			"Queue"="Transparent"
			"RenderType"="Transparent"
			"IgnoreProjector" = "True"
			"ForceNoShadowCasting" = "True"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "False"
		}

		Pass {
			Name "Unlit"
			// Tags {"LightMode" = "UniversalForward"} // Any of URP-specific pass tag not used for a dummy unlit shader
			
			Blend One OneMinusSrcAlpha
			Cull [_Cull]
			ZWrite [_zWrite]
			ZTest [_zTest]
			
			HLSLPROGRAM
#pragma target 2.0
// #pragma target 2.5
// #pragma require derivatives

#pragma vertex vert
#pragma fragment frag

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// ============================================================================
// Structs

struct Attributes {
	float3 positionOS : POSITION;
	half2 texcoord0 : TEXCOORD0;
};

struct Varyings {
	float4 positionCS : SV_POSITION; // HCS = _HOMOGENOUS_ clip space
	half2 uv : TEXCOORD0;
};

// ============================================================================
// Param definitions

TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

CBUFFER_START(UnityPerMaterial)
	// Should not contain conditional definition inside a single shader.
	// All the params that MIGHT be used, should be ALWAYS defined.
	half4 _Color;
	half _TransparentShader;
CBUFFER_END

// ============================================================================
// Vert

Varyings vert (Attributes input)
{
	Varyings output = (Varyings)0;
	output.positionCS = TransformObjectToHClip(input.positionOS);
	output.uv = input.texcoord0;
	return output;
}

// ============================================================================
// Frag

half4 frag (Varyings input) : SV_Target
{
	half4 clr = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _Color;
	
	clr.rgb = saturate(clr.rgb * clr.aaa);
	clr.a *= _TransparentShader;
	return clr;
}
			ENDHLSL
		}
	}
	
	FallBack Off
	
}
