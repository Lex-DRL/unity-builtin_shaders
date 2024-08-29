// DRL: based on the default cleaned-up "UI/Default" shader.
// last synced with: 2022.3.43f1

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

		#pragma multi_compile_local _ UNITY_UI_CLIP_RECT
		#pragma multi_compile_local _ UNITY_UI_ALPHACLIP

		#include "UnityCG.cginc"
		#include "UnityUI.cginc"

		struct appdata_t {
			float3 vertex : POSITION;
			fixed4 color : COLOR;
			half2 texcoord0 : TEXCOORD0;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct v2f {
			float4 positionCS : SV_POSITION;
			fixed4 vColor : COLOR;
			half2 mainUVs : TEXCOORD0;
			#ifdef UNITY_UI_CLIP_RECT
				half4 mask : TEXCOORD1;
			#endif
			UNITY_VERTEX_OUTPUT_STEREO
		};

		sampler2D _MainTex;
		half4 _MainTex_ST;
		fixed4 _TextureSampleAdd;

		fixed4 _Color;

		#ifdef UNITY_UI_CLIP_RECT
			float4 _ClipRect;
			half _UIMaskSoftnessX;
			half _UIMaskSoftnessY;
		#endif

		int _UIVertexColorAlwaysGammaSpace;

		v2f vert(appdata_t v)
		{
			v2f OUT;
			UNITY_SETUP_INSTANCE_ID(v);
			// UNITY_INITIALIZE_OUTPUT(v2f, OUT);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

			float4 clipPos = UnityObjectToClipPos(v.vertex);
			OUT.positionCS = clipPos;
			// float3 worldPosition = v.vertex;
			//
			// DRL:
			// Probably, it's ^ some leftover from ancient versions. Currently,
			// worldPos isn't used anywhere.
			// Moreover, v.vertex IS indeed worldpos... scaled to account for canvas scaling.
			// I.e., if canvas is scaled by 2.0 to make all the icons twice is bigger
			// and resolution is 4K, the mesh's top-right corner is ACTUALLY at (1920, 1080)
			// but obj-to-world matrix scales it by x2.
			// 
			// So:
			// * if you need to account for canvas scale, use raw v.vertex.
			// * if you need the actual pixel-pos on screen, get the true worldPos
			//   (apply unity_ObjectToWorld matrix).

			OUT.mainUVs = TRANSFORM_TEX(v.texcoord0.xy, _MainTex);

			#ifdef UNITY_UI_CLIP_RECT
				half2 pixelSize = clipPos.w;
				pixelSize /= abs(
					mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy)
				);

				float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
				// DRL: I've got no idea why this line was even there in the default UI shader:
				// float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
				OUT.mask = half4(
					v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw,
					0.25h / (0.25h * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy))
				);
			#endif

			if (_UIVertexColorAlwaysGammaSpace && !IsGammaSpace()) {
				v.color.rgb = UIGammaToLinear(v.color.rgb);
			}

			OUT.vColor = v.color * _Color;
			return OUT;
		}


		fixed4 frag(v2f IN) : SV_Target
		{
			//Round up the alpha color coming from the interpolator (to 1.0/256.0 steps)
			//The incoming alpha could have numerical instability, which makes it very sensible to
			//HDR color transparency blend, when it blends with the world's texture.
			static const half alphaPrecision = half(0xff);
			static const half invAlphaPrecision = half(1.0/alphaPrecision);
			IN.vColor.a = round(IN.vColor.a * alphaPrecision) * invAlphaPrecision;

			half4 clr = IN.vColor * (
				tex2D(_MainTex, IN.mainUVs) + _TextureSampleAdd
			);

			#ifdef UNITY_UI_CLIP_RECT
				half2 m = saturate(
					(_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw
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

		Stencil {
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Blend One OneMinusSrcAlpha
		ColorMask [_ColorMask]
		Cull Off
		ZTest [unity_GUIZTestMode]
		ZWrite Off
		Lighting Off

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
