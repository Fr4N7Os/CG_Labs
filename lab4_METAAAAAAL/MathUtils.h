#pragma once
#include <simd/simd.h>
#include <cmath>

class MathUtils {
public:
    static matrix_float4x4 makeIdentity() {
        return matrix_identity_float4x4;
    }

    static matrix_float4x4 makePerspective(float fovY, float aspect, float nearZ, float farZ) {
        float ys = 1.0f / tanf(fovY * 0.5f);
        float xs = ys / aspect;
        float zs = farZ / (nearZ - farZ);
        
        return (matrix_float4x4){{
            { xs,   0,    0,    0 },
            { 0,    ys,   0,    0 },
            { 0,    0,    zs,  -1 },
            { 0,    0,    zs * nearZ, 0 }
        }};
    }

    static matrix_float4x4 makeLookAt(vector_float3 eye, vector_float3 center, vector_float3 up) {
        vector_float3 z = simd_normalize(eye - center);
        vector_float3 x = simd_normalize(simd_cross(up, z));
        vector_float3 y = simd_cross(z, x);
        vector_float3 t = { -simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye) };

        return (matrix_float4x4){{
            { x.x, y.x, z.x, 0 },
            { x.y, y.y, z.y, 0 },
            { x.z, y.z, z.z, 0 },
            { t.x, t.y, t.z, 1 }
        }};
    }

    static matrix_float4x4 makeRotationY(float radians) {
        float c = cos(radians);
        float s = sin(radians);
        return (matrix_float4x4){{
            { c, 0, -s, 0 },
            { 0, 1,  0, 0 },
            { s, 0,  c, 0 },
            { 0, 0,  0, 1 }
        }};
    }
};
