#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Структуры, общие для C++ и Metal
struct Vertex {
    vector_float3 position;
    vector_float3 normal;
    float3 color; // Передаем цвет
};


#endif
