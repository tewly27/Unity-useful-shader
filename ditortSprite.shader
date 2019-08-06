// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/waveEff2"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Intensity("Intensity", Float) = 0.1
	}
	SubShader
	{
		Tags {			
            "Queue"="Transparent" 
            
}
		



		GrabPass
		{
			"_BackgroundTexture"
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;

				float4 grabPos : TEXCOORD1;
				
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BackgroundTexture;
			float _Intensity;
			
			v2f vert (appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 d = tex2D(_MainTex, i.uv);
                d.rgb *= d.a;
				float4 p = i.grabPos + (d * _Intensity);
				fixed4 col = tex2Dproj(_BackgroundTexture, p);


				
				
				return col;
			}
			ENDCG
		}
	}
}
