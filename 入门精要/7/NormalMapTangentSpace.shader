
// 切线空间 法线贴图
//  切线空间定义， 以顶点为原点， 法线为 Z轴， 切线为 X轴
//      优点： 
//      缺点： 
Shader "RuMenJingYao/7/NormalMapTangentSpace" {
    Properties {
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map 法线贴图", 2D) = "bump" {}
        _BumpScale ("Bump Scale 控制凹凸程度", Float) = 1.0
        _Specular ("Specular 高光颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss ("Gloss 高光强度", Range(1.0, 500)) = 20
    }

    SubShader {
        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir: TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            // Unity 不支持矩阵 求逆， 所以自己实现一个
            //  本函数仅演示， 效率不高
            // 具体可参考 : http://answers.unity3d.com/questions/218333/shader-inversefloat4x4-function.html
            float4x4 inverse(float4x4 input) {
                #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
                
                float4x4 cofactors = float4x4(
                     minor(_22_23_24, _32_33_34, _42_43_44), 
                    -minor(_21_23_24, _31_33_34, _41_43_44),
                     minor(_21_22_24, _31_32_34, _41_42_44),
                    -minor(_21_22_23, _31_32_33, _41_42_43),
                    
                    -minor(_12_13_14, _32_33_34, _42_43_44),
                     minor(_11_13_14, _31_33_34, _41_43_44),
                    -minor(_11_12_14, _31_32_34, _41_42_44),
                     minor(_11_12_13, _31_32_33, _41_42_43),
                    
                     minor(_12_13_14, _22_23_24, _42_43_44),
                    -minor(_11_13_14, _21_23_24, _41_43_44),
                     minor(_11_12_14, _21_22_24, _41_42_44),
                    -minor(_11_12_13, _21_22_23, _41_42_43),
                    
                    -minor(_12_13_14, _22_23_24, _32_33_34),
                     minor(_11_13_14, _21_23_24, _31_33_34),
                    -minor(_11_12_14, _21_22_24, _31_32_34),
                     minor(_11_12_13, _21_22_23, _31_32_33)
                );
                #undef minor
                return transpose(cofactors) / determinant(input);
            }

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(i.vertex);
                
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;


                // 构造 从切线空间 变换到 世界空间的  矩阵
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 

                
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);   // 世界空间 到 切线空间  矩阵

                // 光方向 和 视线方向  变换到 切线空间
                o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

                
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {                
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);     // 法线贴图中的  法线值，就是颜色值
                fixed3 tangentNormal;

                tangentNormal = UnpackNormal(packedNormal);     // 不同平台压缩方法不同，此方法获取正确 法线方向
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
                
                return fixed4(ambient + diffuse + specular, 1.0);
            }

            CGEND
        }
    }

    FallBack "Diffuse"
}
