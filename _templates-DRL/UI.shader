// DRL: based on the default cleaned-up "UI/Default" shader.

Shader "DRL/UI-Default"
{
	Properties {
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		[HideInInspector] _StencilComp ("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil ("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp ("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask ("Stencil Read Mask", Float) = 255
		
		[Enum(None,0,Alpha,1,RGB,14,RGBA,15)] _ColorMask ("Color Mask", Float) = 15
		
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}
	
	CGINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		
		#include "UnityCG.cginc"
		#include "UnityUI.cginc"
		
		#pragma multi_compile_local _ UNITY_UI_CLIP_RECT
		#pragma multi_compile_local _ UNITY_UI_ALPHACLIP
		
		struct appdata
		{
			float3 vertex : POSITION;
			fixed4 color : COLOR;
			half2 tex0 : TEXCOORD0;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};
		
		struct v2f
		{
			float4 vertex : SV_POSITION;
			fixed4 vColor : COLOR;
			half2 mainUVs : TEXCOORD0;
			half4 mask : TEXCOORD2;
			UNITY_VERTEX_OUTPUT_STEREO
		};
		
		half4 _MainTex_ST;
		
		fixed4 _Color;
		
		#ifdef UNITY_UI_CLIP_RECT
			float4 _ClipRect;
			half _UIMaskSoftnessX;
			half _UIMaskSoftnessY;
		#endif
		
		v2f vert(appdata v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v)
			// UNITY_INITIALIZE_OUTPUT(v2f, o)
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)
			
			float4 clipPos = UnityObjectToClipPos(v.vertex);
			// float3 worldPosition = v.vertex;
			o.vertex = clipPos;
			o.vColor = v.color * _Color;
			o.mainUVs = TRANSFORM_TEX(v.tex0, _MainTex);
			
			#ifdef UNITY_UI_CLIP_RECT
				half2 pixelSize = clipPos.w;
				pixelSize /= abs(
					mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy)
				);
				
				float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
				// DRL: I've got no idea why this line was even there in the default UI shader:
				// float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
				o.mask = half4(
					v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw,
					0.25h / (0.25h * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy))
				);
			#endif
			
			return o;
		}
		
		sampler2D _MainTex;
		fixed4 _TextureSampleAdd;
		
		fixed4 frag(v2f i) : SV_Target
		{
			half4 clr = i.vColor * (
				tex2D(_MainTex, i.mainUVs) + _TextureSampleAdd
			);
			
			#ifdef UNITY_UI_CLIP_RECT
				half2 m = saturate(
					(_ClipRect.zw - _ClipRect.xy - abs(i.mask.xy)) * i.mask.zw
				);
				clr.a *= m.x * m.y;
			#endif
			
			#ifdef UNITY_UI_ALPHACLIP
				clip (clr.a - 0.001);
			#endif
			
			clr.rgb *= clr.a;
			
			return clr;
		}
	ENDCG
	
	Category {
		Tags {
			"Queue"="Transparent"
			"RenderType"="Transparent"
			"CanUseSpriteAtlas"="True"
			"IgnoreProjector"="True"
			"PreviewType"="Plane"
		}
		
		Blend One OneMinusSrcAlpha
		ColorMask [_ColorMask]
		Cull Off
		ZTest [unity_GUIZTestMode]
		ZWrite Off
		Lighting Off
		
		Stencil {
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}
		
		SubShader { Pass {
			Name "Default"
			CGPROGRAM
			#pragma target 2.0
			ENDCG
		} }
		SubShader { Pass {
			Name "Default"
			CGPROGRAM
			// default shader target. Presumably, 2.5
			ENDCG
		} }
	}
	
	// CustomEditor "DRL_ShadersGUI.Editor.ClearingKeywords"
	
	FallBack Off
	
}
