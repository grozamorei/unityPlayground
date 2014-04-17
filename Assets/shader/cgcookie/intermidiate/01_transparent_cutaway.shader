Shader "Custom/unityCookieIntermidiate/01_transparent_cutaway" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color      ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _Height     ("Cutoff Height", Range(-1.0, 2.0)) = 1.0
        _Atten      ("Attenuation", Range (0.1, 2.0)) = 1.0
    }

    SubShader {
        Tags 
        { 
            "Queue" = "Transparent" 
        }

        Pass {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform fixed4 _Color;
            uniform fixed _Height;
            uniform fixed _Atten;

            //unity variables
            uniform half4 _LightColor0;

            //input structs
            struct vertexInput
            {
                half4 vertex   : POSITION;
            };

            struct vertexOutput
            {
                half4 sv_pos : SV_POSITION;
                half4 vert_pos : TEXCOORD0;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // common routines
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.vert_pos = vi.vertex;
                
                return vo;
            }

            //fragment
            fixed4 frag(vertexOutput vo) : COLOR
            {
                if (vo.vert_pos.y > _Height) {
                    discard;
                }
                return _Color;
            }

            ENDCG
        }
    }
    Fallback Off
}
