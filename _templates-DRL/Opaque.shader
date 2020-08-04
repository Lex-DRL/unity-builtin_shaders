Shader "DRL/DefaultClean-Opaque" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		
		[Space] [Header(Shader Blending)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 0
		[Enum(None,0,Alpha,1,RGB,14,RGBA,15)] _ColorMask ("out Color Mask", Float) = 15
		[Enum(Off, 0, On, 1)] _zWrite ("Z-Write", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _zTest ("Z-Test", Int) = 2
	}
	
	CGINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		
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
			fixed4 col = tex2D(_MainTex, i.mainUVs);
			return col;
		}
	ENDCG
	
	Category {
		Tags {
			"RenderType"="Opaque"
			"PreviewType"="Plane"
			"IgnoreProjector"="True"
			"ForceNoShadowCasting"="True"
		}
		
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
	
}
