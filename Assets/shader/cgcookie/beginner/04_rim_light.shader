Shader "Custom/unityCookieBeguinner/04_rim_light" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecColor ("Specular color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess ("Shininess", Float) = 10
        _RimColor ("Rim color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower ("Rim power", Range(0.1, 10.0)) = 3.0
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
            uniform float4 _SpecColor;
            uniform float _Shininess;
            uniform float4 _RimColor;
            uniform float _RimPower;
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
                vo.normal_dir = normalize(mul(float4(vi.normal, 0.0), _World2Object).xyz);
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                return vo;
            }

            //fragment
            float4 frag(vertexOutput vo) : COLOR
            {
            	float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - vo.pos_world.xyz);
            	float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);

            	// lighting
            	float3 diffuse_product = saturate(dot(vo.normal_dir, light_dir));
            	float3 diffuse_ref = _Atten * _LightColor0.rgb * diffuse_product;
            	float3 specular_ref = _Atten * _LightColor0.rgb * diffuse_product * 
            		pow(saturate(dot(reflect(-light_dir, vo.normal_dir), view_dir)), _Shininess);

        		// rim
            	float rim = 1- saturate(dot(normalize(view_dir), vo.normal_dir));
            	float3 rim_light = _Atten * _LightColor0.rgb * _RimColor * 
            		saturate(dot(vo.normal_dir, light_dir)) * pow(rim, _RimPower);

        		float3 light_final = (rim_light + diffuse_ref/* + specular_ref*/ + UNITY_LIGHTMODEL_AMBIENT.rgb) * _Color.rgb;
        		return  float4(light_final, 1.0);
            }

            ENDCG
        }
    }
    Fallback Off
}
