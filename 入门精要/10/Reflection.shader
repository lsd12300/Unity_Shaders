
// 反射
//  物体表面像镀层金属，可以在物体表面看到周围的环境
//     在 顶点着色器中 计算反射方向， 比 片元着色器中 计算量少，提升性能
//  配合 Camera.RenderToCubemap() 可实时采样周围环境
//     
//      优点：
//      缺点：
Shader "RuMenJingYao/10/Reflection" {
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _ReflectColor ("Reflection Color 反射的颜色", Color) = (1, 1, 1, 1)
        _ReflectAmount ("Reflect Amount 反射程度", Range(0, 1)) = 1
        _Cubemap ("Reflection Cubemap  模拟反射的环境映射纹理", Cube) = "_Skybox" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        
        Pass { 
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            
            #pragma multi_compile_fwdbase
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
            samplerCUBE _Cubemap;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };
            
            v2f vert(a2v v) {
                v2f o;
                
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                o.worldPos = mul(_Object2World, v.vertex).xyz;
                
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);  // 世界空间 反射方向
                
                TRANSFER_SHADOW(o);
                
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));      
                fixed3 worldViewDir = normalize(i.worldViewDir);        
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 使用 世界空间反射方向  采样环境纹理
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // 混合 漫反射颜色 和 反射颜色
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;
                
                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
