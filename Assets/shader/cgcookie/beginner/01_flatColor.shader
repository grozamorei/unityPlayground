Shader "Custom/unityCookieBeguinner/01_flatColor" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader {
        Pass {
            CGPROGRAM

            //pragmas
            #pragma vertex vert
            #pragma fragment frag

            //variables
            uniform float4 _Color;

            //input structs
            struct vertexInput
            {
                float4 vertex : POSITION;
            };

            struct vertexOutput
            {
                float4 sv_pos : SV_POSITION;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                return vo;
            }

            //fragment
            float4 frag(vertexOutput vo) : COLOR
            {
                return _Color;
            }

            ENDCG
        }
    }
    Fallback Off
}
