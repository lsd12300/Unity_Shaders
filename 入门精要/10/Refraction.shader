
// 折射
//  斯涅尔定律： 折射率1 * sin(入射角) = 折射率2 * sin(折射角)
//     
//      优点：
//      缺点：
Shader "RuMenJingYao/10/Refraction" {
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _RefractColor ("Refraction Color", Color) = (1, 1, 1, 1)
        _RefractAmount ("Refraction Amount", Range(0, 1)) = 1
        // 不同介质的透射比， 值为  入射介质折射率/出射介质折射率
        _RefractRatio ("Refraction Ratio", Range(0.1, 1)) = 0.5
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}
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
            fixed4 _RefractColor;
            float _RefractAmount;
            fixed _RefractRatio;
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
                fixed3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4)
            };
            
            v2f vert(a2v v) {
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                o.worldPos = mul(_Object2World, v.vertex).xyz;
                
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                
                // 世界空间  折射方向
                o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);
                
                TRANSFER_SHADOW(o);
                
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);
                                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 使用 折射方向  对环境纹理 进行采样
                fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // Mix the diffuse color with the refract color
                fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;
                
                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    } 
    FallBack "Reflective/VertexLit"
}
