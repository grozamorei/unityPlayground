﻿Shader "Custom/unityCookieBeguinner/02b_lambert_ambient_frag" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Atten ("Attenuation", Range (0.1, 1.0)) = 1.0
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
                float4 pos_world : TEXCOORD0;
                float3 normal_dir : TEXCOORD1;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.pos_world = mul(_Object2World, vi.vertex);
                vo.normal_dir = normalize(mul(float4(vi.normal, 0.0), _World2Object).xyz);

                return vo;
            }

            //fragment
            
            float4 frag(vertexOutput vo) : COLOR
            {
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                float3 diffuse_prod = saturate(dot(vo.normal_dir, light_dir));
                float3 diffuse_reflection = _Atten * _LightColor0.rbg * diffuse_prod;
                float3 light_final = (diffuse_reflection + UNITY_LIGHTMODEL_AMBIENT) * _Color;
                return float4(light_final, 1.0);
            }

            ENDCG
        }
    }
    Fallback Off
}
