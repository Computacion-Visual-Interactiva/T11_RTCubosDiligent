#include "structures.fxh"
#include "RayUtils.fxh"

ConstantBuffer<CubeAttribs> g_CubeAttribsCB;

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in BuiltInTriangleIntersectionAttributes attr)
{
    // Reconstruct world‐space normal
    float3 b = float3(1 - attr.barycentrics.x - attr.barycentrics.y,
                      attr.barycentrics.x,
                      attr.barycentrics.y);
    uint3 prim = g_CubeAttribsCB.Primitives[PrimitiveIndex()].xyz;
    float3 n = normalize(
        mul((float3x3)ObjectToWorld3x4(),
            g_CubeAttribsCB.Normals[prim.x].xyz * b.x +
            g_CubeAttribsCB.Normals[prim.y].xyz * b.y +
            g_CubeAttribsCB.Normals[prim.z].xyz * b.z)
    );

    // Spawn a reflection ray
    RayDesc ray;
    ray.Origin    = WorldRayOrigin() + WorldRayDirection() * RayTCurrent() + n * SMALL_OFFSET;
    ray.Direction = reflect(WorldRayDirection(), n);
    ray.TMin      = 0;
    ray.TMax      = 1e3;

    // Cast and forward its color
    PrimaryRayPayload refl = CastPrimaryRay(ray, payload.Recursion + 1);
    payload.Color = refl.Color;
    payload.Depth = RayTCurrent();
}
