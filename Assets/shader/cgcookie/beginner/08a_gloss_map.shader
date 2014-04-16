Shader "Custom/unityCookieBeguinner/08a_gloss_map" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color      ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex    ("Diffuse Texture, Gloss (A)", 2D) = "white" {}
        _BumpMap    ("Normal Texture", 2D) = "bump" {}
        _BumpDepth  ("Bump depth", Range(0.5, 3.0)) = 1.0

        _SpecColor  ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess  ("Shininess", Float) = 10

        _RimColor   ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower   ("Rim Power", Range(0.1, 10.0)) = 3.0

        _Atten      ("Attenuation", Range (0.1, 1.0)) = 1.0
    }

    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers flash

            //user variables
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform float4 _BumpMap_ST;
            uniform float _BumpDepth;

            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;
            uniform float _Atten;

            //unity variables
            uniform float4 _LightColor0;

            //input structs
            struct vertexInput
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent  : TANGENT;
            };

            struct vertexOutput
            {
                float4 sv_pos : SV_POSITION;
                float4 tex : TEXCOORD0;
                float4 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 tangent_world : TEXCOORD3;
                float3 binormal_world : TEXCOORD4;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;
                
                vo.normal_world = normalize(
                    mul(float4(vi.normal, 0.0), _World2Object).xyz
                );
                vo.tangent_world = normalize(
                    mul(_Object2World, vi.tangent).xyz
                );
                vo.binormal_world = normalize(
                    cross(vo.normal_world, vo.tangent_world) * vi.tangent.w
                );

                vo.pos_world = mul(_Object2World, vi.vertex);
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.tex = vi.texcoord;

                return vo;
            }

            //fragment
            
            float4 frag(vertexOutput vo) : COLOR
            {
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - vo.pos_world.xyz);

                float att;
                float3 light_dir;

                // uncool light source calculations: 
                if (_WorldSpaceLightPos0.w == 0.0) {
                    att = _Atten;
                    light_dir = normalize(_WorldSpaceLightPos0.xyz);
                } else {
                    float3 fragment_to_light_source = _WorldSpaceLightPos0.xyz - vo.pos_world.xyz;
                    float distance = length(fragment_to_light_source);
                    att = _Atten/distance;
                    light_dir = normalize(fragment_to_light_source);
                }

                // texture map
                float4 tex = tex2D(_MainTex, vo.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                float4 tex_bump = tex2D(_BumpMap, vo.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

                // unpack normal
                float3 local_coords = float3(2.0 * tex_bump.ag - float2(1.0, 1.0), 0.0);
                local_coords.z = _BumpDepth; //1.0 - 0.5 * dot(local_coords, local_coords);
                    //normal transpose matrix
                float3x3 local_2_world_trans = float3x3(
                    vo.tangent_world,
                    vo.binormal_world,
                    vo.normal_world
                );
                float3 normal_dir = normalize(mul(local_coords, local_2_world_trans));

                // lighting
                float3 diffuse_ref = att * _LightColor0.xyz * saturate(dot(normal_dir, light_dir));
                float3 spec_ref = diffuse_ref * _SpecColor.xyz * pow(saturate(dot(reflect(-light_dir, normal_dir), view_dir)), _Shininess);
                // rim lighting
                float rim = 1 - saturate(dot(view_dir, normal_dir));
                float3 rim_light = saturate(dot(normal_dir, light_dir) * _RimColor.xyz * _LightColor0.xyz * pow(rim, _RimPower));

                float3 light_final = UNITY_LIGHTMODEL_AMBIENT.xyz + diffuse_ref + (spec_ref * tex.a) + rim_light;


                return float4(tex.xyz * light_final * _Color, 1.0);
            }

            ENDCG
        }

        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers flash

            //user variables
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform float4 _BumpMap_ST;
            uniform float _BumpDepth;

            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;
            uniform float _Atten;

            //unity variables
            uniform float4 _LightColor0;

            //input structs
            struct vertexInput
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent  : TANGENT;
            };

            struct vertexOutput
            {
                float4 sv_pos : SV_POSITION;
                float4 tex : TEXCOORD0;
                float4 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 tangent_world : TEXCOORD3;
                float3 binormal_world : TEXCOORD4;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;
                
                vo.normal_world = normalize(
                    mul(float4(vi.normal, 0.0), _World2Object).xyz
                );
                vo.tangent_world = normalize(
                    mul(_Object2World, vi.tangent).xyz
                );
                vo.binormal_world = normalize(
                    cross(vo.normal_world, vo.tangent_world) * vi.tangent.w
                );

                vo.pos_world = mul(_Object2World, vi.vertex);
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.tex = vi.texcoord;

                return vo;
            }

            //fragment
            
            float4 frag(vertexOutput vo) : COLOR
            {
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - vo.pos_world.xyz);

                float att;
                float3 light_dir;

                // uncool light source calculations: 
                if (_WorldSpaceLightPos0.w == 0.0) {
                    att = _Atten;
                    light_dir = normalize(_WorldSpaceLightPos0.xyz);
                } else {
                    float3 fragment_to_light_source = _WorldSpaceLightPos0.xyz - vo.pos_world.xyz;
                    float distance = length(fragment_to_light_source);
                    att = _Atten/distance;
                    light_dir = normalize(fragment_to_light_source);
                }

                // texture map
                float4 tex = tex2D(_MainTex, vo.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                float4 tex_bump = tex2D(_BumpMap, vo.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

                // unpack normal
                float3 local_coords = float3(2.0 * tex_bump.ag - float2(1.0, 1.0), 0.0);
                local_coords.z = _BumpDepth; //1.0 - 0.5 * dot(local_coords, local_coords);
                    //normal transpose matrix
                float3x3 local_2_world_trans = float3x3(
                    vo.tangent_world,
                    vo.binormal_world,
                    vo.normal_world
                );
                float3 normal_dir = normalize(mul(local_coords, local_2_world_trans));

                // lighting
                float3 diffuse_ref = att * _LightColor0.xyz * saturate(dot(normal_dir, light_dir));
                float3 spec_ref = diffuse_ref * _SpecColor.xyz * pow(saturate(dot(reflect(-light_dir, normal_dir), view_dir)), _Shininess);
                // rim lighting
                float rim = 1 - saturate(dot(view_dir, normal_dir));
                float3 rim_light = saturate(dot(normal_dir, light_dir) * _RimColor.xyz * _LightColor0.xyz * pow(rim, _RimPower));

                float3 light_final = diffuse_ref + (spec_ref * tex.a) + rim_light;


                return float4(light_final * _Color, 1.0);
            }
            ENDCG
        }
    }
    Fallback Off
}
