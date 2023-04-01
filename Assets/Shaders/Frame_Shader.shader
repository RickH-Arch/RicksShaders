Shader "Ricks Shader/Frame_Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius("Radius",float) = 0.1
        _Ratio("Ratio",float) = 1
        [Header(Border)]
        _BorderWidth("BorderWidth",float) = 0.004
        _BorderColor("BorderColor",color) = (0,0,0)
        [Header(Inner Fade)]
        _TLFadeWidth("TopLeftFadeWidth",float) = 0.1
        _BRFadeWidth("ButtomRightFadeWidth",float) = 0.3
        _FadeColor("FadeColor",color) = (0,0,0)
        [Header(Outer Fade)]
        _OuterFadeWidth("OuterFadeWidth",float) = 0.03
        _OuterFadeColor("OuterFadeColor",color) = (0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        
        GrabPass{"_BaseDrawingTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Radius;
            float _Ratio;

            float _BorderWidth;
            fixed4 _BorderColor;

            float _TLFadeWidth;
            float _BRFadeWidth;
            fixed4 _FadeColor;

            float _OuterFadeWidth;
            fixed4 _OuterFadeColor;
            sampler2D _BaseDrawingTex;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //compute tex uv in screenPos
                float2 texuv = i.scrPos.xy/i.scrPos.w;
                fixed4 col = tex2D(_MainTex,texuv);
                fixed4 backCol = tex2D(_BaseDrawingTex,texuv);

                //transform uv max to center
                float2 p = abs(step(0.5,i.uv)-i.uv);

                //get to radius center length
                float dis = length(float2(p.x-_Radius,p.y*_Ratio-_Radius));

                //get fillet
                                //in left or right corner//in top or bottom corner//out of fillet
                float isOutFillet = step(_Radius,p.x)||step(_Radius,p.y*_Ratio)||step(dis,_Radius);
                if(isOutFillet == 0){
                    discard;
                }

                //Border
                float isBorder = 0;
                isBorder += _OuterFadeWidth<p.x && p.x<= _BorderWidth+_OuterFadeWidth;
                isBorder += _OuterFadeWidth<p.y*_Ratio &&p.y*_Ratio<= _BorderWidth+_OuterFadeWidth;
                isBorder += _OuterFadeWidth<(_Radius-dis) && (_Radius-dis)<=_BorderWidth+_OuterFadeWidth && p.x<_Radius && p.y*_Ratio<_Radius;
                if(isBorder>0)col = _BorderColor;

                //outer uniform Fade 
                float isOuter = 0;
                isOuter += p.x<= _OuterFadeWidth;
                isOuter += p.y*_Ratio<=_OuterFadeWidth;
                isOuter += (_Radius-dis)<=_OuterFadeWidth && p.x<_Radius && p.y*_Ratio<_Radius;

                float outerFadeFac;
                float outerFadeFacX = p.x/_OuterFadeWidth;
                outerFadeFacX = (1-outerFadeFacX)*step(outerFadeFacX,1);
                float outerFadeFacY = p.y*_Ratio/_OuterFadeWidth;
                outerFadeFacY = (1-outerFadeFacY)*step(outerFadeFacY,1);
                float outerFadeFacCor = (_Radius-dis)/_OuterFadeWidth;
                outerFadeFacCor = (1-outerFadeFacCor)*step(1-outerFadeFacCor,1)*step(p.x,_Radius)*step(p.y*_Ratio,_Radius);
                outerFadeFac = max(max(outerFadeFacX,outerFadeFacY),outerFadeFacCor);
                backCol = lerp(backCol,backCol*_OuterFadeColor,smoothstep(0,1,1-outerFadeFac));
                if(isOuter>0)col = backCol;

                //inner ununiform fade
                //top-left fade
                float tlFadeFac;
                float tlFadeFacX = 0;
                if(i.uv.x<0.5){
                    tlFadeFacX = p.x*step( p.x,_TLFadeWidth);
                    tlFadeFacX = saturate(tlFadeFacX/_TLFadeWidth);
                    tlFadeFacX = (1-tlFadeFacX)*(1-step(tlFadeFacX,0));
                }
                float tlFadeFacY = 0;
                if(i.uv.y>0.5){
                    tlFadeFacY = p.y*_Ratio*step(p.y*_Ratio,_TLFadeWidth);
                    tlFadeFacY = saturate(tlFadeFacY/_TLFadeWidth);
                    tlFadeFacY = (1-tlFadeFacY)*(1-step(tlFadeFacY,0));
                }
                //Bottom-right fade
                float brFadeFac;
                float brFadeFacX = 0;
                if(i.uv.x>0.5){
                    brFadeFacX = p.x*step( p.x,_BRFadeWidth);
                    brFadeFacX = saturate(brFadeFacX/_BRFadeWidth);
                    brFadeFacX = (1-brFadeFacX)*(1-step(brFadeFacX,0));
                }
                float brFadeFacY = 0;
                if(i.uv.y<0.5){
                    brFadeFacY = p.y*_Ratio*step(p.y*_Ratio,_BRFadeWidth);
                    brFadeFacY = saturate(brFadeFacY/_BRFadeWidth);
                    brFadeFacY = (1-brFadeFacY)*(1-step(brFadeFacY,0));
                }

                tlFadeFac = max(tlFadeFacX,tlFadeFacY);
                brFadeFac = max(brFadeFacX,brFadeFacY);
                float fadeFac = max(brFadeFac,tlFadeFac);
                if(isOuter==0&&isBorder == 0){
                    col = lerp(col,col*_FadeColor,smoothstep(0,1,fadeFac));
                }


                return col;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
