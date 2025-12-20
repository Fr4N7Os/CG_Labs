//
//  Shaders.metal
//  metal_po_venam_goog
//
//  Created by Bulat Zhamalov on 20.12.2025.
//

#include <metal_stdlib>
#include "ShaderTypes.h" // Подключаем общий хедер

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float3 color; // Передаем цвет
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float3 cameraPos;
    float3 lightPos;
    float3 lightColor;
};



vertex VertexOut vertex_main(uint vid [[vertex_id]],
                             constant Vertex *verts [[buffer(0)]],
                             constant Uniforms &unis [[buffer(1)]]) {
    VertexOut out;
    out.position = unis.viewProjectionMatrix * unis.modelMatrix * float4(verts[vid].position, 1.0);
    out.worldPos = (unis.modelMatrix * float4(verts[vid].position, 1.0)).xyz;
    out.normal = (unis.modelMatrix * float4(verts[vid].normal, 0.0)).xyz;
    out.color = verts[vid].color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &unis [[buffer(1)]]) {
    float3 N = normalize(in.normal);
    float3 L = normalize(unis.lightPos - in.worldPos);
    float3 V = normalize(unis.cameraPos - in.worldPos);
    float3 R = reflect(-L, N);

    float3 baseColor = in.color; // Используем цвет грани вместо unis.lightColor в диффузе
    
    float3 ambient = 0.2 * baseColor;
    float diff = max(dot(N, L), 0.0);
    float3 diffuse = diff * baseColor * unis.lightColor;
    
    float spec = pow(max(dot(V, R), 0.0), 32.0);
    float3 specular = spec * unis.lightColor;

    return float4(ambient + diffuse + specular, 1.0);
}
