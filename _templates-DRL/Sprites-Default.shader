// DRL: based on the default cleaned-up "Sprites/Default" shader.
// last synced with: 2022.3.17f1

Shader "DRL/Sprites-Default"
{
	Properties {
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)

		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
		[HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
		[HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
		[PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
		[PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0
	}

	CGINCLUDE
		#pragma vertex SpriteVert
		#pragma fragment SpriteFrag

		#pragma multi_compile_instancing
		#pragma multi_compile_local _ PIXELSNAP_ON
		#pragma multi_compile _ ETC1_EXTERNAL_ALPHA

		#include "UnitySprites.cginc"
	ENDCG

	Category {
		Tags {
			"Queue"="Transparent"
			"RenderType"="Transparent"
			"CanUseSpriteAtlas"="True"
			"IgnoreProjector"="True"
			"PreviewType"="Plane"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		SubShader { Pass {
			CGPROGRAM
			#pragma target 2.0
			ENDCG
		} }
	}

	FallBack Off

}
