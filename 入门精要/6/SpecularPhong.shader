
// Phong 高光反射
//      优点： 较平滑的高光效果
//      缺点： 
Shader "RuMenJingYao/6/Specular Phong" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
        _Specular ("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss ("Gloss 高光强度", Range(8.0, 256)) = 20
    }

    SubShader {
        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

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
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);     // 从 物体局部空间 变换到 投影空间

                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);   // 世界空间  法线

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);   // 世界空间  顶点坐标

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 ambient = UNITY_LIGHTmODEL_AMBIENT.xyz;  // 环境光颜色

                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);    // 世界空间  光源方向

                // 漫反射 颜色
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));   // 世界空间  反射方向

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);  // 世界空间  视线方向

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                // 最终颜色 = 环境光颜色 + 漫反射颜色
                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1.0);
            }

            CGEND
        }
    }

    FallBack "Diffuse"
}
