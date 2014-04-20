Shader "Custom/unityCookieIntermidiate/04_anisotropic_light" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color      ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecColor  ("Specular color", Color) = (1.0, 1.0, 1.0, 1.0)
        _AniX       ("Anisotropic X", Range(0.0, 2.0)) = 1.0
        _AniY       ("Anisotropic Y", Range(0.0, 2.0)) = 1.0
        _Shininess  ("Shininess", Float) = 10.0
    }

    SubShader {
        Pass {
            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform fixed4 _Color;
            uniform fixed4 _SpecColor;
            uniform fixed _AniX;
            uniform fixed _AniY;
            uniform half _Shininess;

            //unity variables
            uniform half4 _LightColor0;

            //input structs
            struct vertexInput
            {
                half4 vertex   : POSITION;
                half3 normal   : NORMAL;
                half4 tangent  : TANGENT;
            };
            struct vertexOutput
            {
                half4 sv_pos        : SV_POSITION;
                fixed3 normal_dir   : TEXCOORD0;
                fixed4 light_dir    : TEXCOORD1;
                fixed3 view_dir     : TEXCOORD2;
                fixed3 tangent_dir  : TEXCOORD3;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // mesh normal direction
                vo.normal_dir = normalize(mul(fixed4(vi.normal, 0.0), _World2Object).xyz);
                // tangent direction
                vo.tangent_dir = normalize(mul(_Object2World, half4(vi.tangent.xyz, 0.0)).xyz);
                // unity transform position
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                
                // world position
                half4 pos_world = mul(_Object2World, vi.vertex);
                // view direction
                vo.view_dir = normalize((pos_world - _WorldSpaceCameraPos).xyz);
                // light direction
                half3 fragment_to_light_source = _WorldSpaceLightPos0.xyz - pos_world.xyz;
                vo.light_dir = fixed4(
                    normalize(lerp(_WorldSpaceLightPos0.xyz, fragment_to_light_source, _WorldSpaceLightPos0.w)),
                    lerp(1.0, 1.0/length(fragment_to_light_source), _WorldSpaceLightPos0.w)
                );

                return vo;
            }

            //fragment
            fixed4 frag(vertexOutput vo) : COLOR
            {
                //Lighting
                fixed3 half_vec = normalize(vo.light_dir.xyz + vo.view_dir);
                half3 binormal_dir = cross(vo.normal_dir, vo.tangent_dir);

                //dot products
                fixed n_dot_l = dot(vo.normal_dir, vo.light_dir.xyz);
                fixed n_dot_h = dot(vo.normal_dir, half_vec);
                fixed n_dot_v = dot(vo.normal_dir, vo.view_dir);
                fixed t_dot_hx = dot(vo.tangent_dir, half_vec) / _AniX;
                fixed b_dot_hy = dot(binormal_dir, half_vec) / _AniY;

                //diffuse
                fixed3 diffuse_ref = vo.light_dir.w * _LightColor0.xyz * saturate(n_dot_l);
                //specular
                fixed3 spec_ref = diffuse_ref * _SpecColor * exp(-(t_dot_hx * t_dot_hx + b_dot_hy * b_dot_hy)) * _Shininess;

                fixed3 light_final = spec_ref + diffuse_ref + UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                return fixed4(light_final * _Color.xyz, 1.0);
            }

            ENDCG
        }
    }
    Fallback Off
}
