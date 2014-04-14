Shader "Custom/unityCookieBeguinner/02_lambert" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Atten ("Attenuation", Range (0.1, 1)) = 1.0
    }

    SubShader {
        Pass {
        	Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform float4 _Color;
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
                float4 clr : COLOR;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // normal direction in the world coordinates (normalized)
                float3 normal_dir = normalize(
                        mul(
                            float4(vi.normal, 0.0), 
                            _World2Object
            	       ).xyz
                    );

                // rotation of the directional light
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);

                // dot product between normal and light direction (and truncating to zero)
                float3 normal_vs_light_prod = max(
                        0.0,
                        dot(
                            normal_dir,
                            light_dir
                        )
                    );

                // multiply dot product with light color and attenuation(intencity)
                float3 diff_ref = _Atten * _LightColor0.xyz * _Color.rgb * normal_vs_light_prod;
                
                // set the collor of the result diffuse
                vo.clr = float4(diff_ref, 1.0);

                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                return vo;
            }

            //fragment
            float4 frag(vertexOutput vo) : COLOR
            {
                return vo.clr;
            }

            ENDCG
        }
    }
    Fallback Off
}
