#include "structures.fxh"
#include "RayUtils.fxh"

// Per-triangle normals + UVs etc. for our cube mesh
ConstantBuffer<CubeAttribs> g_CubeAttribsCB;

// Simple “random” color per instance
float3 RandomColor(uint id)
{
    return float3(
        frac(sin(id * 12.9898) * 43758.5453),
        frac(sin((id + 17) * 78.233) * 12345.6789),
        frac(sin((id + 42) * 23.123) * 98765.4321)
    );
}

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in BuiltInTriangleIntersectionAttributes attr)
{
    // 1) Reconstruct world‐space normal
    float3 bary = float3(1 - attr.barycentrics.x - attr.barycentrics.y,
                         attr.barycentrics.x,
                         attr.barycentrics.y);
    uint3 prim = g_CubeAttribsCB.Primitives[PrimitiveIndex()].xyz;
    float3 n = g_CubeAttribsCB.Normals[prim.x].xyz * bary.x +
               g_CubeAttribsCB.Normals[prim.y].xyz * bary.y +
               g_CubeAttribsCB.Normals[prim.z].xyz * bary.z;
    n = normalize(mul((float3x3)ObjectToWorld3x4(), n));

    // 2) Basic Lambertian: ambient + N·L
    float3 worldPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();
    uint   id       = InstanceIndex();
    float3 baseCol  = RandomColor(id);
    float3 col      = g_ConstantsCB.AmbientColor.rgb * baseCol;

    [unroll]
    for (uint i = 0; i < NUM_LIGHTS; ++i)
    {
        float3 L   = normalize(g_ConstantsCB.LightPos[i].xyz - worldPos);
        float  NdotL = saturate(dot(n, L));
        col += NdotL * g_ConstantsCB.LightColor[i].rgb * baseCol;
    }

    payload.Color = col;
    payload.Depth = RayTCurrent();
}
