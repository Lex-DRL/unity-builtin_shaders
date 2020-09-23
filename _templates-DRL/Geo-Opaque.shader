Shader "DRL/DefaultClean-Geo-Opaque" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		
		// [HDR] _Color ("Color", Color) = (.1, .5, 1, 1)
		// [PowerSlider(3.333333)] _PowerParm ("Logarithmic parm", Range(0, 10)) = 1
		// _VectorParm ("Vector parm", Vector) = (0.5, 1, 1, 0)
		
		// [DropdownKeywords(No, One, 1, Two, 2)] Dropdown_mode ("Mode parm", Int) = 0
		// [ToggleLeft(DRL_KW_3)] Checkbox_mode ("Toggle parm", Int) = 1
		
		[Space] [Header(Shader Blending)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
		[Enum(None,0,Alpha,1,RGB,14,RGBA,15)] _ColorMask ("out Color Mask", Float) = 15
		[Enum(Off, 0, On, 1)] _zWrite ("Z-Write", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _zTest ("Z-Test", Int) = 2
	}
	
	CGINCLUDE
		#pragma vertex vert
		#pragma geometry geom
		#pragma fragment frag
		
		// #pragma multi_compile_local _ DRL_AZAZA
		// #pragma shader_feature_local _ DRL_KW_1 DRL_KW_2
		// #pragma shader_feature_local _ DRL_KW_3
		
		#include "UnityCG.cginc"
		
		struct appdata {
			float3 vertex : POSITION;
			half3 normal : NORMAL;
			half4 tangent : TANGENT;
			half2 tex0 : TEXCOORD0;
		};
		
		struct v2g {
			float4 worldPos : SV_POSITION;
			half3 worldNormal : NORMAL;
			half4 worldTangent : TANGENT;
			half2 mainUVs : TEXCOORD0;
		};
		
		struct g2f {
			float4 pos : SV_POSITION;
			half2 mainUVs : TEXCOORD0;
			fixed4 clr : COLOR;
		};
		
		v2g vert (appdata v)
		{
			v2g o;
			// o.pos = UnityObjectToClipPos(v.vertex);
			o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex, 1.0));
			o.worldNormal = UnityObjectToWorldNormal(v.normal); // nN
			o.worldTangent = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w); // nT
			o.mainUVs = v.tex0;
			return o;
		}
		
		#undef DRL_GEO_N
		#define DRL_GEO_N 3
		
		[maxvertexcount(DRL_GEO_N)]
		void geom(triangle v2g g[DRL_GEO_N], inout TriangleStream<g2f> triStream)
		{
			g2f og;
			
			const fixed4 colors[4] = {
				fixed4(1.0, 0.15, 0.1, 1.0), // ~red
				fixed4(0.15, 1.0, 0.1, 1.0), // ~green
				fixed4(0.1, 0.15, 1.0, 1.0), // ~blue
				fixed4(0.5, 0.5, 0.5, 1.0), // grey
			};
			
			for(int i = 0; i < DRL_GEO_N; i++) {
				og.pos = UnityWorldToClipPos(g[i].worldPos.xyz);
				og.mainUVs = g[i].mainUVs;
				og.clr = colors[i];
				
				triStream.Append(og);
			}
			triStream.RestartStrip();
		}
		
		sampler2D _MainTex;
		
		fixed4 frag (g2f i) : SV_Target
		{
			fixed4 clr = tex2D(_MainTex, i.mainUVs);
			clr = lerp(clr, i.clr, (fixed4)0.9);
			return clr;
		}
	ENDCG
	
	Category {
		Tags {
			// "PreviewType"="Plane"
			"RenderType"="Opaque"
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
			// #pragma target 2.0
			#pragma require geometry
			ENDCG
		} }
		//SubShader { Pass {
		//	CGPROGRAM
		//	// default shader target. Presumably, 2.5
		//	ENDCG
		//} }
	}
	
	// CustomEditor "DRL_ShadersGUI.Editor.ClearingKeywords"
	
	FallBack Off
	
}
