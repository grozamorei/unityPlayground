Shader "Custom/unityCookieIntermidiate/02_transparent_map" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color      ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _TransMap   ("Transparency (A)", 2D) = "white" {}
        _Atten      ("Attenuation", Range (0.1, 2.0)) = 1.0
    }

    SubShader {
        Tags 
        { 
            "Queue" = "Transparent" 
        }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            Cull Off
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform fixed4 _Color;
            uniform sampler2D _TransMap;
            uniform half4 _TransMap_ST;
            uniform fixed _Atten;

            //unity variables
            uniform half4 _LightColor0;

            //input structs
            
            struct vertexInput
            {
                half4 vertex   : POSITION;
                half4 texcoord : TEXCOORD0;
            };


            struct vertexOutput
            {
                half4 sv_pos : SV_POSITION;
                half4 tex : TEXCOORD0;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // common routines
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.tex = vi.texcoord;
                
                return vo;
            }

            //fragment
            fixed4 frag(vertexOutput vo) : COLOR
            {
                //texture maps
                half4 tex = tex2D(_TransMap, _TransMap_ST.xy * vo.tex.xy + _TransMap_ST.zw);
                fixed alpha = tex.b * _Color.a * _Atten;
                
                return fixed4(_Color.rgb, alpha);
            }

            ENDCG
        }
    }
    Fallback Off
}
