

Shader "Sprites/Blend"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		[KeywordEnum(Normal, Add, Multiply, Overlay, Color)] _Blend("Blend mode", Float) = 0
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
		_HueShift("HueShift", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		GrabPass{
			"_Color2"
		}

		Pass
		{
		CGPROGRAM
			




			#pragma vertex vert
			#pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
			#include "UnityCG.cginc"
			
			fixed4 _Color;
			sampler2D _Color2;

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 grabPos : TEXCOORD1;
				
			};
			
			

			v2f vert(appdata_t IN)
			{
				v2f OUT;

				
				
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.grabPos = ComputeGrabScreenPos(OUT.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color * _Color;



				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			float _Blend;
			float _HueShift;

			fixed4 SampleSpriteTexture (float2 uv)
			{
				fixed4 color = tex2D (_MainTex, uv);


				return color;
			}

			float3 HUEtoRGB(in float H)
			{
				float R = abs(H * 6 - 3) - 1;
				float G = 2 - abs(H * 6 - 2);
				float B = 2 - abs(H * 6 - 4);
				return saturate(float3(R,G,B));
			}

			float Epsilon = 1e-10;
 
			float3 RGBtoHCV(in float3 RGB)
			{
				
				float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
				float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
				float C = Q.x - min(Q.w, Q.y);
				float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
				return float3(H, C, Q.x);
			}
			float3 HSVtoRGB(in float3 HSV)
			{
				float3 RGB = HUEtoRGB(HSV.x);
				return ((RGB - 1) * HSV.y + 1) * HSV.z;
			}
			float3 RGBtoHSV(in float3 RGB)
			{
				float3 HCV = RGBtoHCV(RGB);
				float S = HCV.y / (HCV.z + Epsilon);
				return float3(HCV.x, S, HCV.z);
			}


			fixed4 frag(v2f IN) : SV_Target
			{

				fixed4 c = SampleSpriteTexture (IN.texcoord) * IN.color;
                fixed4 _ColorB = tex2Dproj(_Color2, IN.grabPos);
                
				

				if(_Blend == 0){

				}

				else if(_Blend == 1){
					c.rgb += _ColorB;
				}

				else if(_Blend == 2){
					c.rgb *= _ColorB;
				}


				else if(_Blend == 3){                
					if(c.r <= 0.5){
						c.r *= _ColorB.r *2 ;
					}else{
						c.r = 1 - 2*(1-_ColorB.r)*(1-c.r);
					}
					if(c.g <= 0.5){
						c.g *= _ColorB.g *2;
					}else{
						c.g = 1 - 2*(1-_ColorB.g)*(1-c.g);
					}
					if(c.b <= 0.5){
						c.b *= _ColorB.b *2;
					}else{
						c.b = 1 - 2*(1-_ColorB.b)*(1-c.b);
					}
				}
				else if(_Blend == 4){
					float3 hsv = RGBtoHSV(c.rgb);
					float3 hsvB = RGBtoHSV(_ColorB.rgb);
					hsvB.y = hsv.y;
					hsvB.x = hsv.x + (_HueShift - round(_HueShift));


					if ( hsv.x > 1.0 ) { hsv.x -= 1.0; }
					c.rgb = half3(HSVtoRGB(hsvB));
				}
				
				c.rgb *= c.a;

				return c;
			}
		ENDCG
		}
	}
}