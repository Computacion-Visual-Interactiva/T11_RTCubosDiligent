#include "structures.fxh"
#include "RayUtils.fxh"

// Simple per-instance “random” albedo
float3 RandomAlbedo(uint id)
{
    return frac(sin(float3(id, id+17, id+42) * float3(12.9898, 78.233, 23.123)) * 43758.5453);
}

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in ProceduralGeomIntersectionAttribs attribs)
{
    // 1) Compute intersection data
    float3 worldPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();
    float3 normal   = normalize(mul((float3x3)ObjectToWorld3x4(), attribs.Normal));
    uint   instID   = InstanceIndex();
    float3 albedo   = RandomAlbedo(instID);

    // 2) Scatter in random hemisphere around normal
    //    Use the first DiscPoint for jitter
    float2 dpt      = g_ConstantsCB.DiscPoints[0].xy;
    float3 jitter   = normalize(normal + float3(dpt.x, dpt.y, 0));
    RayDesc ray;
    ray.Origin     = worldPos + normal * SMALL_OFFSET;
    ray.Direction  = jitter;
    ray.TMin       = 0.0;
    ray.TMax       = 1e6;

    // 3) Bounce once
    PrimaryRayPayload bounced = CastPrimaryRay(ray, payload.Recursion + 1);

    // 4) Apply albedo
    float3 color = bounced.Color * albedo;

    // 5) Local lighting (diffuse+shadow+ambient)
    LightingPass(color, worldPos, normal, payload.Recursion);

    payload.Color = color;
    payload.Depth = RayTCurrent();
}
