Shader "AVR/Heart2D"
{
    //心形公式
    //着色
    //跳动分布、频率
    Properties
    {
		_BaseColor("Base Color", Color) = (0.5, 0.5, 0.5, 1)
        _BaseColor2("Base Color2", Color) = (0.5, 0.5, 0.5, 1)
        _ColorBlendSpeed("Color Blend Speed" ,float) = 1
        _HeartBeatSpeed("Heart Beat Speed", float) = 1
        _HeartSize("Heart Size", float) = 0.7
        _HeartCenter("Heart Center (XY)", vector) = (-1, -1, 0, 0)
        _UVScale("UV Scale", float) = 1
        _Edge("Edge", float) = 1
        [HDR]_EdgeColor("Edge Color", color) = (1,1,1,1)
    }
    SubShader
    {        
        Tags { "RenderType" = "Transparent" "Queue"="Transparent" }
		
		//SrcAlpha
		//OneMinusSrcAlpha
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite off
		ColorMask RGB
		Cull off
		
        LOD 300

        Pass
        {
            Cull off

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag                       
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half4 _BaseColor2;
            half4 _BackColor;
            float _ColorBlendSpeed;
            float _HeartSize;
            float2 _HeartCenter;
            float _UVScale;
            float _HeartBeatSpeed;
            float _Edge;
            float4 _EdgeColor;
            CBUFFER_END
		
            struct Attributes 
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };
            
            struct Varyings 
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float4 color : COLOR;
            };		 
            
            float Maskline(float pos,float lineNumber)
            {    
              return step(pos,0.1428571428571429 * lineNumber) - (step(pos,0.1428571428571429 * (lineNumber - 1.)));
            }
            
            float3 GetRainbowColor(float i)
            {
                //Step Violet
                float3 Violet = 	float3(0.57,0.0, 1.0) 	*  Maskline(i,7.);
                float3 Purple = 	float3(0.27,0.0, 0.51)	*  Maskline(i,6.);
                float3 blue 	=	float3(0.0, 	0.0, 1.0) 	*  Maskline(i,5.);
                float3 Green	=	float3(0.0, 	1.0, 0.0) 	*  Maskline(i,4.);
                float3 Yellow =	float3(1.0, 	1.0, 0.0) 	*  Maskline(i,3.);
                float3 Orange =	float3(1.0, 	0.5, 0.0) 	*  Maskline(i,2.);
                float3 Red	=	float3(1.0, 	0.0, 0.0) 	*  Maskline(i,1.);
                return Violet + Purple + blue + Green + Yellow + Orange + Red;
            }
            
            float3 smoothRainbowColor(float i)
            {
                i *= 0.1428571428571429 * 6;
                float gradinStep = fmod(i, 0.1428571428571429) * 7;
                float3 firstColor = GetRainbowColor(i);
                float3 nextColor = GetRainbowColor(i + 0.1428571428571429);
                return lerp(firstColor, nextColor, gradinStep);
            }              
                
            Varyings vert(Attributes input) 
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);                
                output.uv = input.texcoord;
                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                output.positionWS = vertexInput.positionWS;
                output.color = input.color;
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
			{
			    float a = (input.uv.x + _HeartCenter.x)/_UVScale;
			    float b = (input.uv.y + _HeartCenter.y)/_UVScale;
			    float a2 = a*a;
			    float b2 = b*b;
			    float b3 = b2 * b;	
			    float heatSize = _HeartSize;
			    float heartEdge = pow((a2 + b2 - heatSize), 3) - a2*b3;
                heartEdge = step(0, heartEdge);
                float blendVlaue = abs(sin(_ColorBlendSpeed * _Time.y));
                half4 blendColor = half4(smoothRainbowColor(blendVlaue), 1);//lerp(_BaseColor, _BaseColor2, blendVlaue);
			    half4 color = blendColor * (1 - heartEdge) * input.color;				    			          
			    
			    float heartEdge2 = pow((a2 + b2 - heatSize + _Edge), 3) - a2*b3;
			    float diffEdge = heartEdge2 - heartEdge;
                diffEdge = step(0, diffEdge);
                color.rgb += diffEdge * _EdgeColor;
                return color; 
			}
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
