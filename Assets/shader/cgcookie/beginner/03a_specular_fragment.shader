Shader "Custom/unityCookieBeguinner/03a_specular_fragment" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess ("Shininess", Float) = 10
        _Atten ("Attenuation", Range (0, 1)) = 1.0
    }

    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float _Shininess;
            uniform float _Atten;

            //unity variables
            uniform float4 _LightColor0;

            //input structs
            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct vertexOutput
            {
                float4 sv_pos : SV_POSITION;
                float4 pos_world : TEXCOORD0;
                float3 normal_dir : TEXCOORD1;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                vo.pos_world = mul(_Object2World, vi.vertex);
                // normal direction in the world coordinates (normalized)
                vo.normal_dir = 
                    normalize(
                        mul(
                            float4(vi.normal, 0.0), 
                            _World2Object
                       ).xyz
                    );

                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                return vo;
            }

            //fragment
            float4 frag(vertexOutput vo) : COLOR
            {
                // determine the direction from witch we looking at object
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - vo.pos_world.xyz);
                // rotation of light source
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                // calculated diffuse reflection dot product
                float3 diffuse_prod = max(0.0, dot(vo.normal_dir, light_dir));
                // lambertian diffuse reflection with color
                float3 diff_ref = _Atten * _LightColor0.xyz * diffuse_prod;
                // specular reflection
                float3 spec_ref = _Atten * _SpecColor.rgb * diffuse_prod * 
                    pow( 
                        max(
                            0.0, 
                            dot(reflect(-light_dir, vo.normal_dir), view_dir)
                       ),
                        _Shininess
                   );

                // final light is a summ of all the reflection calculations times tint color
                float3 light_specular = (diff_ref + spec_ref + UNITY_LIGHTMODEL_AMBIENT) * _Color;

                return float4(light_specular, 1.0);
            }

            ENDCG
        }
    }
    Fallback Off
}
