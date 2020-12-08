
// 半兰伯特光照模型
//    漫反射颜色 = (光源颜色 * 材质漫反射颜色) * (0.5 * (表面法线 * 光线方向) + 0.5)
//    半兰伯特模型无任何物理依据，仅是 视觉加强技术
//      优点： 背光面也有明暗变化
//      缺点： 
Shader "RuMenJingYao/6/Half Lambert" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader {
        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);     // 从 物体局部空间 变换到 投影空间

                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);   // 世界空间  法线

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 ambient = UNITY_LIGHTmODEL_AMBIENT.xyz;  // 环境光颜色

                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);    // 世界空间  光源方向

                // 漫反射 颜色
                fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;

                // 最终颜色 = 环境光颜色 + 漫反射颜色
                fixed3 color = ambient + diffuse;

                return fixed4(color, 1.0);
            }

            CGEND
        }
    }

    FallBack "Diffuse"
}
