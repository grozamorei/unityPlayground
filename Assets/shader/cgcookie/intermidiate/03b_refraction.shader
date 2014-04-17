Shader "Custom/unityCookieIntermidiate/03b_refraction" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Cube           ("Cube map", Cube) = "" {}
        _RefractionIndex   ("Refract Index", Range(1.01, 2.0)) = 1.5
    }

    SubShader {
        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform samplerCUBE _Cube;
            uniform fixed _RefractionIndex;

            //input structs
            struct vertexInput
            {
                half4 vertex    : POSITION;
                fixed3 normal   : NORMAL;
            };
            struct vertexOutput
            {
                half4 sv_pos        : SV_POSITION;
                fixed3 normal_dir   : TEXCOORD0;
                fixed3 view_dir     : TEXCOORD1;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // common routines
                vo.normal_dir = normalize(mul(fixed4(vi.normal, 0.0), _World2Object).xyz);
                vo.view_dir = (mul(_Object2World, vi.vertex) - _WorldSpaceCameraPos).xyz;
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                
                return vo;
            }

            //fragment
            fixed4 frag(vertexOutput vo) : COLOR
            {
                //reflect the ray based on the normals to get the cube coordinates
                fixed3 reflect_dir = refract(vo.view_dir, vo.normal_dir, 1/_RefractionIndex);

                //texture maps
                fixed4 tex_cube = texCUBE(_Cube, reflect_dir);
                
                return tex_cube;
            }

            ENDCG
        }
    }
    Fallback Off
}
