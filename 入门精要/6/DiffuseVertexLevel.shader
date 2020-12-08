// 逐顶点光照
Shader "RuMenJingYao/6/Diffuse Vertex-Level" {
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
                fixed3 color : COLOR;
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);     // 从 物体局部空间 变换到 投影空间

                fixed3 ambient = UNITY_LIGHTmODEL_AMBIENT.xyz;  // 环境光颜色

                // 法线 变换到 世界空间
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);    // 世界空间  光源方向

                // 漫反射 颜色
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                // 最终颜色 = 环境光颜色 + 漫反射颜色
                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                return fixed4(i.color, 1.0);
            }

            CGEND
        }
    }

    FallBack "Diffuse"
}
