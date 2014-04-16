Shader "Custom/unityCookieBeguinner/09_optimized" {

    Properties {
        // VARIABLE NAME ("DISPLAYED NAME", TYPE) = VALUE
        _Color      ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex    ("Diffuse Texture", 2D) = "white" {}
        _BumpMap    ("Normal Texture", 2D) = "bump" {}
        _BumpDepth  ("Bump depth", Range(0., 2.0)) = 1.0
        _EmitMap    ("Emission Texture", 2D) = "black" {}
        _EmitStr    ("Emit Strength", Range(0.0, 2.0)) = 0.0

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

            //user variables
            uniform sampler2D _MainTex;
            uniform half4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform half4 _BumpMap_ST;
            uniform sampler2D _EmitMap;
            uniform half4 _EmitMap_ST;

            uniform fixed4 _Color;
            uniform fixed4 _SpecColor;
            uniform fixed4 _RimColor;
            uniform fixed _Atten;
            uniform half _Shininess;
            uniform half _RimPower;
            uniform fixed _BumpDepth;
            uniform fixed _EmitStr;

            //unity variables
            uniform half4 _LightColor0;

            //input structs
            struct vertexInput
            {
                half4 vertex   : POSITION;
                half3 normal   : NORMAL;
                half4 texcoord : TEXCOORD0;
                half4 tangent  : TANGENT;
            };

            struct vertexOutput
            {
                half4 sv_pos : SV_POSITION;
                half4 tex : TEXCOORD0;
                fixed4 light_dir : TEXCOORD1;
                fixed3 view_dir : TEXCOORD2;
                fixed3 normal_world : TEXCOORD3;
                fixed3 tangent_world : TEXCOORD4;
                fixed3 binormal_world : TEXCOORD5;
            };

            //vertex
            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // common routines
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.tex = vi.texcoord;
                
                // normal map calc
                vo.normal_world = normalize(mul(half4(vi.normal, 0.0), _World2Object).xyz);    
                vo.tangent_world = normalize(mul(_Object2World, vi.tangent).xyz);               
                vo.binormal_world = normalize(cross(vo.normal_world, vo.tangent_world) * vi.tangent.w);


                half4 pos_world = mul(_Object2World, vi.vertex);
                vo.view_dir = normalize(_WorldSpaceCameraPos.xyz - pos_world.xyz);

                // cool light source calculation (for both directional an point light)
                half3 fragment_to_light_source = _WorldSpaceLightPos0.xyz - pos_world.xyz;

                //xyz - normal direction
                //w - attenuation
                vo.light_dir = fixed4(
                    normalize(lerp(_WorldSpaceLightPos0.xyz, fragment_to_light_source, _WorldSpaceLightPos0.w)), 
                    lerp(_Atten, _Atten/length(fragment_to_light_source), _WorldSpaceLightPos0.w)
                );

                // uncool light source calculations: 
                // if (_WorldSpaceLightPos0.w == 0.0) {
                    // att = _Atten;
                    // light_dir = normalize(_WorldSpaceLightPos0.xyz);
                // } else {
                    // float3 fragment_to_light_source = _WorldSpaceLightPos0.xyz - vo.pos_world.xyz;
                    // float distance = length(fragment_to_light_source);
                    // att = _Atten/distance;
                    // light_dir = normalize(fragment_to_light_source);
                // }

                return vo;
            }

            //fragment
            
            fixed4 frag(vertexOutput vo) : COLOR
            {
                // texture map
                fixed4 tex = tex2D(_MainTex, vo.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                fixed4 tex_bump = tex2D(_BumpMap, vo.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);
                fixed4 tex_emit = tex2D(_EmitMap, vo.tex.xy * _EmitMap_ST.xy + _EmitMap_ST.zw);

                // unpack normal
                fixed3 local_coords = fixed3(2.0 * tex_bump.ag - fixed2(1.0, 1.0), _BumpDepth/*1.0 - 0.5 * dot(local_coords, local_coords)*/);

                //normal transpose matrix
                fixed3x3 local_2_world_trans = fixed3x3(
                    vo.tangent_world,
                    vo.binormal_world,
                    vo.normal_world
                );
                // unpacked normal direction result:
                fixed3 normal_dir = normalize(mul(local_coords, local_2_world_trans));

                // lighting
                // normal dot light
                fixed n_dot_l = saturate(dot(normal_dir, vo.light_dir.xyz));

                fixed3 diffuse_ref = vo.light_dir.w * _LightColor0.xyz * n_dot_l;
                fixed3 spec_ref = diffuse_ref * _SpecColor.xyz * pow(saturate(dot(reflect(-vo.light_dir.xyz, normal_dir), vo.view_dir)), _Shininess);
                // rim lighting
                fixed rim = 1 - n_dot_l;
                fixed3 rim_light = (n_dot_l * _RimColor.xyz * _LightColor0.xyz * pow(rim, _RimPower));

                fixed3 light_final = UNITY_LIGHTMODEL_AMBIENT.xyz + diffuse_ref + (spec_ref * tex.a) + rim_light + (tex_emit * _EmitStr);

                return fixed4(tex.xyz * light_final * _Color, 1.0);
            }

            ENDCG
        }

        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //user variables
            uniform sampler2D _MainTex;
            uniform half4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform half4 _BumpMap_ST;
            uniform sampler2D _EmitMap;
            uniform half4 _EmitMap_ST;

            uniform fixed4 _Color;
            uniform fixed4 _SpecColor;
            uniform fixed4 _RimColor;
            uniform fixed _Atten;
            uniform half _Shininess;
            uniform half _RimPower;
            uniform fixed _BumpDepth;
            uniform fixed _EmitStr;

            //unity variables
            uniform half4 _LightColor0;

            //input structs
            struct vertexInput
            {
                half4 vertex   : POSITION;
                half3 normal   : NORMAL;
                half4 texcoord : TEXCOORD0;
                half4 tangent  : TANGENT;
            };

            struct vertexOutput
            {
                half4 sv_pos : SV_POSITION;
                half4 tex : TEXCOORD0;
                fixed4 light_dir : TEXCOORD1;
                fixed3 view_dir : TEXCOORD2;
                fixed3 normal_world : TEXCOORD3;
                fixed3 tangent_world : TEXCOORD4;
                fixed3 binormal_world : TEXCOORD5;
            };

            vertexOutput vert(vertexInput vi)
            {
                vertexOutput vo;

                // common routines
                vo.sv_pos = mul(UNITY_MATRIX_MVP, vi.vertex);
                vo.tex = vi.texcoord;
                
                // normal map calc
                vo.normal_world = normalize(mul(half4(vi.normal, 0.0), _World2Object).xyz);    
                vo.tangent_world = normalize(mul(_Object2World, vi.tangent).xyz);               
                vo.binormal_world = normalize(cross(vo.normal_world, vo.tangent_world) * vi.tangent.w);


                half4 pos_world = mul(_Object2World, vi.vertex);
                vo.view_dir = normalize(_WorldSpaceCameraPos.xyz - pos_world.xyz);

                // cool light source calculation (for both directional an point light)
                half3 fragment_to_light_source = _WorldSpaceLightPos0.xyz - pos_world.xyz;

                //xyz - normal direction
                //w - attenuation
                vo.light_dir = fixed4(
                    normalize(lerp(_WorldSpaceLightPos0.xyz, fragment_to_light_source, _WorldSpaceLightPos0.w)), 
                    lerp(_Atten, _Atten/length(fragment_to_light_source), _WorldSpaceLightPos0.w)
                );

                return vo;
            }

            fixed4 frag(vertexOutput vo) : COLOR
            {
                // texture map
                fixed4 tex = tex2D(_MainTex, vo.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                fixed4 tex_bump = tex2D(_BumpMap, vo.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

                // unpack normal
                fixed3 local_coords = fixed3(2.0 * tex_bump.ag - fixed2(1.0, 1.0), _BumpDepth/*1.0 - 0.5 * dot(local_coords, local_coords)*/);

                //normal transpose matrix
                fixed3x3 local_2_world_trans = fixed3x3(
                    vo.tangent_world,
                    vo.binormal_world,
                    vo.normal_world
                );
                // unpacked normal direction result:
                fixed3 normal_dir = normalize(mul(local_coords, local_2_world_trans));

                // lighting
                // normal dot light
                fixed n_dot_l = saturate(dot(normal_dir, vo.light_dir.xyz));

                fixed3 diffuse_ref = vo.light_dir.w * _LightColor0.xyz * n_dot_l;
                fixed3 spec_ref = diffuse_ref * _SpecColor.xyz * pow(saturate(dot(reflect(-vo.light_dir.xyz, normal_dir), vo.view_dir)), _Shininess);
                // rim lighting
                fixed rim = 1 - n_dot_l;
                fixed3 rim_light = (n_dot_l * _RimColor.xyz * _LightColor0.xyz * pow(rim, _RimPower));

                fixed3 light_final = diffuse_ref + (spec_ref * tex.a) + rim_light;

                return fixed4(light_final, 1.0);
            }

            ENDCG
        }
    }
    Fallback Off
}
