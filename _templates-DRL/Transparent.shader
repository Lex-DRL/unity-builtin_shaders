Shader "DRL/DefaultClean-Opaque" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		
		// [HDR] _Color ("Color", Color) = (.1, .5, 1, 1)
		// [PowerSlider(3.333333)] _PowerParm ("Logarithmic parm", Range(0, 10)) = 1
		// _VectorParm ("Vector parm", Vector) = (0.5, 1, 1, 0)
		
		// [DropdownKeywords(No, One, 1, Two, 2)] Dropdown_mode ("Mode parm", Int) = 0
		// [ToggleLeft(DRL_KW_3)] Checkbox_mode ("Toggle parm", Int) = 1
		
		[Space] [Header(Shader Blending)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 0
		[Enum(None,0,Alpha,1,RGB,14,RGBA,15)] _ColorMask ("out Color Mask", Float) = 15
		[Enum(Off, 0, On, 1)] _zWrite ("Z-Write", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _zTest ("Z-Test", Int) = 2
	}
	
	CGINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		
		// #pragma multi_compile _ DRL_AZAZA
		// #pragma shader_feature _ DRL_KW_1 DRL_KW_2
		// #pragma shader_feature _ DRL_KW_3
		
		#include "UnityCG.cginc"
		
		struct appdata {
			float3 vertex : POSITION;
			half2 tex0 : TEXCOORD0;
		};
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 mainUVs : TEXCOORD0;
		};
		
		v2f vert (appdata v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.mainUVs = v.tex0;
			return o;
		}
		
		sampler2D _MainTex;
		
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 clr = tex2D(_MainTex, i.mainUVs);
			return clr;
		}
	ENDCG
	
	Category {
		Tags {
			// "PreviewType"="Plane"
			"Queue"="Transparent"
			"RenderType"="Transparent"
			"IgnoreProjector"="True"
			"ForceNoShadowCasting"="True"
		}
		
		Blend One OneMinusSrcAlpha
		ColorMask [_ColorMask]
		Cull [_Cull]
		ZTest [_zTest]
		ZWrite [_zWrite]
		Lighting Off
		
		SubShader { Pass {
			CGPROGRAM
			#pragma target 2.0
			ENDCG
		} }
		SubShader { Pass {
			CGPROGRAM
			// default shader target. Presumably, 2.5
			ENDCG
		} }
	}
	
	// CustomEditor "DRL_ShadersGUI.Editor.ClearingKeywords"
	
	FallBack Off
	
}
