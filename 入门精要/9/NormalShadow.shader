
// 常规阴影，
//  实现：投射阴影 和 接收阴影
// 
//  使用 AutoLight.cginc 中定义的宏
//      SHADOW_COORDS       // 会声明一个 _ShadowCoord 的阴影纹理坐标变量
//      TRANSFER_SHADOW     // 使用 屏幕空间阴影映射技术 或 传统阴影映射技术  计算 _ShadowCoord 的值
//      SHADOW_ATTENUATION  // 使用 _ShadowCoord 对纹理进行采样， 获得 阴影信息
//  
//  如果 FallBack 指定的 shader带 ShadowCaster， 可以不用手写 ShadowCaster 的 Pass
//  
//      优点：
//      缺点：
Shader "RuMenJingYao/9/NormalShadow" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        
        Pass {
            Tags { "LightMode"="ForwardBase" }
        
            CGPROGRAM
            
            // 声明保证  光照衰减等 光照变量可以被正确赋值
            #pragma multi_compile_fwdbase   
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;

                // 内建宏，声明对阴影纹理进行采样的坐标
                //  参数为  下一个可用的 插值寄存器的 索引值
                //  TEXCOOR0--为第0个插值寄存器
                SHADOW_COORDS(2)
            };
            
            v2f vert(a2v v) {
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(_Object2World, v.vertex).xyz;
                
                // 内建宏， 计算阴影纹理坐标
                TRANSFER_SHADOW(o);
                
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);  // 内建宏，计算光照衰减和阴影
                
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            
            ENDCG
        }
    
        // 渲染阴影， 默认在 FallBack "Specular" 中也有定义
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v){
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag (v2f i) : SV_Target{
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
