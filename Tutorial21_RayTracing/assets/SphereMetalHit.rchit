#include "structures.fxh"
#include "RayUtils.fxh"

// Per-instance base tint
float3 RandomTint(uint id)
{
    return frac(sin(float3(id, id+31, id+17) * float3(12.9898,78.233,45.164)) * 43758.5453);
}

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in ProceduralGeomIntersectionAttribs attribs)
{
    float3 worldPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();
    float3 normal   = normalize(mul((float3x3)ObjectToWorld3x4(), attribs.Normal));
    uint   instID   = InstanceIndex();
    float3 albedo   = RandomTint(instID) * 0.8 + 0.2; // darker metal

    // reflect with small fuzz from DiscPoints
    float3 viewDir = -WorldRayDirection();
    float3 reflDir = reflect(viewDir, normal);
    float2 dpt     = g_ConstantsCB.DiscPoints[1].xy * 0.05; // fuzz amount
    float3 fuzzDir = normalize(reflDir + float3(dpt.x, dpt.y, 0));

    RayDesc ray;
    ray.Origin    = worldPos + normal * SMALL_OFFSET;
    ray.Direction = fuzzDir;
    ray.TMin      = 0.0;
    ray.TMax      = 1e6;

    PrimaryRayPayload env = CastPrimaryRay(ray, payload.Recursion + 1);

    // 80% reflection, 20% base tint
    float3 color = lerp(albedo, env.Color, 0.8);

    LightingPass(color, worldPos, normal, payload.Recursion);

    payload.Color = color;
    payload.Depth = RayTCurrent();
}
