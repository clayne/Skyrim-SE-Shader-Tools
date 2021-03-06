// Lighting
// TechniqueID: 0x3026201
//
// Technique: 0Sh0_Vc_Spc_Shd_DfSh_Aspc_Parallax

#include "Common.h"
#include "LightingPSHeader.h"
#include "ParallaxEffect.h"

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD4,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD2,
  float4 v5 : TEXCOORD3,
  float4 v6 : TEXCOORD5,
  float4 v7 : TEXCOORD8,
  float4 v8 : TEXCOORD9,
  float3 v9 : TEXCOORD10,
  float4 v10 : POSITION1,
  float4 v11 : POSITION2,
  float4 v12 : COLOR0,
  float4 v13 : COLOR1,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1,
  out float4 o2 : SV_Target2)
{
  const float4 icb[] = { { 1.000000, 0, 0, 0},
                              { 0, 1.000000, 0, 0},
                              { 0, 0, 1.000000, 0},
                              { 0, 0, 0, 1.000000} };
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = dot(v6.xyz, v6.xyz);
  r0.x = rsqrt(r0.x);
  r0.yzw = v6.xyz * r0.xxx;
  r1.xy = GetParallaxCoords(v1.xy, v6.xyz, v3.xyz, v4.xyz, v5.xyz);
  r2.xyzw = TexDiffuseSampler.Sample(DiffuseSampler, r1.xy).xyzw;
  r1.xyzw = TexNormalSampler.Sample(NormalSampler, r1.xy).xyzw;
  r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.x = min(7, cb2[29].x);
  r4.x = dot(v3.xyz, r1.xyz);
  r4.y = dot(v4.xyz, r1.xyz);
  r4.z = dot(v5.xyz, r1.xyz);
  r3.y = dot(r4.xyz, r4.xyz);
  r3.y = rsqrt(r3.y);
  r4.xyz = r4.xyz * r3.yyy;
  r3.yz = cb12[44].xy * v0.xy;
  r3.yz = r3.yz * cb0[2].xy + cb0[2].zw;
  r3.yz = cb12[43].xy * r3.yz;
  r3.yz = max(float2(0,0), r3.yz);
  r5.x = min(cb12[44].z, r3.y);
  r5.y = min(cb12[43].y, r3.z);
  r5.xyzw = TexShadowMaskSampler.Sample(ShadowMaskSampler, r5.xy).xyzw;
  r3.yzw = cb2[1].xyz * r5.xxx;
  r6.x = saturate(dot(r4.xyz, cb2[0].xyz));
  r6.xyz = r6.xxx * r3.yzw;
  r7.xyz = v6.xyz * r0.xxx + cb2[0].xyz;
  r6.w = dot(r7.xyz, r7.xyz);
  r6.w = rsqrt(r6.w);
  r7.xyz = r7.xyz * r6.www;
  r6.w = saturate(dot(r7.xyz, r4.xyz));
  r6.w = log2(r6.w);
  r6.w = cb1[4].w * r6.w;
  r6.w = exp2(r6.w);
  r3.yzw = r6.www * r3.yzw;
  r6.w = cmp(0 < r3.x);
  if (r6.w != 0) {
    r6.w = min(4, cb2[29].y);
    r7.xyz = r6.xyz;
    r8.xyz = r3.yzw;
    r7.w = 0;
    while (true) {
      r8.w = cmp(r7.w >= r3.x);
      if (r8.w != 0) break;
      r8.w = cmp(r7.w < r6.w);
      if (r8.w != 0) {
        r8.w = (uint)r7.w;
        r8.w = dot(cb2[2].xyzw, icb[r8.w+0].xyzw);
        r8.w = (uint)r8.w;
        r8.w = dot(r5.xyzw, icb[r8.w+0].xyzw);
      } else {
        r8.w = 1;
      }
      r9.x = (int)r7.w;
      r9.yzw = cb2[r9.x+15].xyz + -v2.xyz;
      r10.x = dot(r9.yzw, r9.yzw);
      r10.y = sqrt(r10.x);
      r10.y = saturate(r10.y / cb2[r9.x+15].w);
      r10.y = -r10.y * r10.y + 1;
      r11.xyz = cb2[r9.x+22].xyz * r8.www;
      r8.w = rsqrt(r10.x);
      r9.xyz = r9.yzw * r8.www;
      r8.w = saturate(dot(r4.xyz, r9.xyz));
      r10.xzw = r11.xyz * r8.www;
      r9.xyz = v6.xyz * r0.xxx + r9.xyz;
      r8.w = dot(r9.xyz, r9.xyz);
      r8.w = rsqrt(r8.w);
      r9.xyz = r9.xyz * r8.www;
      r8.w = saturate(dot(r9.xyz, r4.xyz));
      r8.w = log2(r8.w);
      r8.w = cb1[4].w * r8.w;
      r8.w = exp2(r8.w);
      r9.xyz = r11.xyz * r8.www;
      r8.xyz = r9.xyz * r10.yyy + r8.xyz;
      r7.xyz = r10.xzw * r10.yyy + r7.xyz;
      r7.w = 1 + r7.w;
    }
    r6.xyz = r7.xyz;
    r3.yzw = r8.xyz;
  }
  r4.w = 1;
  r5.x = dot(cb2[11].xyzw, r4.xyzw);
  r5.y = dot(cb2[12].xyzw, r4.xyzw);
  r5.z = dot(cb2[13].xyzw, r4.xyzw);
  r5.xyz = cb2[4].yzw + r5.xyz;
  r5.xyz = r5.xyz + r6.xyz;
  r5.xyz = cb1[8].yzw * cb1[8].xxx + r5.xyz;
  r2.xyz = r5.xyz * r2.xyz;
  r5.xyz = v12.xyz * r2.xyz;
  r6.x = dot(cb12[12].xyzw, v10.xyzw);
  r6.y = dot(cb12[13].xyzw, v10.xyzw);
  r0.x = dot(cb12[15].xyzw, v10.xyzw);
  r6.xy = r6.xy / r0.xx;
  r7.x = dot(cb12[16].xyzw, v11.xyzw);
  r7.y = dot(cb12[17].xyzw, v11.xyzw);
  r0.x = dot(cb12[19].xyzw, v11.xyzw);
  r6.zw = r7.xy / r0.xx;
  r6.xy = r6.xy + -r6.zw;
  r6.xy = float2(-0.5,0.5) * r6.xy;
  r3.xyz = r3.yzw * r1.www;
  r3.xyz = cb2[3].yyy * r3.xyz;
  r0.x = saturate(dot(r4.xyz, r0.yzw));
  r0.x = 1 + -r0.x;
  r0.x = log2(r0.x);
  r0.x = cb2[14].w * r0.x;
  r0.x = exp2(r0.x);
  r4.w = 0.150000;
  r7.x = saturate(dot(cb2[11].xyzw, r4.xyzw));
  r7.y = saturate(dot(cb2[12].xyzw, r4.xyzw));
  r7.z = saturate(dot(cb2[13].xyzw, r4.xyzw));
  r0.yzw = cb2[14].xyz * r7.xyz;
  r0.xyz = r0.yzw * r0.xxx;
  r0.xyz = r3.xyz * cb1[4].xyz + r0.xyz;
  r2.xyz = -r2.xyz * v12.xyz + v13.xyz;
  r2.xyz = v13.www * r2.xyz + r5.xyz;
  r2.xyz = -r2.xyz * cb0[0].www + r5.xyz;
  r2.xyz = r2.xyz * cb12[42].yyy + cb0[1].xxx;
  r2.xyz = min(r5.xyz, r2.xyz);
  r0.xyz = r2.xyz + r0.xyz;
  r2.xyz = v13.xyz + -r0.xyz;
  r2.xyz = v13.www * r2.xyz + r0.xyz;
  r2.xyz = -r2.xyz * cb0[0].www + r0.xyz;
  r3.xyz = cb12[42].yyy * r2.xyz;
  r2.xyz = r2.xyz * cb12[42].yyy + cb0[1].zzz;
  r0.xyz = min(r2.xyz, r0.xyz);
  r0.w = cb2[3].z * r2.w;
  o0.w = v12.w * r0.w;
  o0.xyz = -r3.xyz * cb12[42].zzz + r0.xyz;
  r0.x = cmp(0.000010 < cb2[7].z);
  o1.xy = r0.xx ? float2(1,0) : r6.xy;
  r0.x = dot(v7.xyz, r1.xyz);
  r0.y = dot(v8.xyz, r1.xyz);
  r0.z = dot(v9.xyz, r1.xyz);
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r0.w = -0.000010 + cb2[7].x;
  r1.x = cb2[7].y + -r0.w;
  r0.w = r1.w + -r0.w;
  r1.x = 1 / r1.x;
  r0.w = saturate(r1.x * r0.w);
  r1.x = r0.w * -2 + 3;
  r0.w = r0.w * r0.w;
  r0.w = r1.x * r0.w;
  o2.w = cb2[7].w * r0.w;
  r0.z = r0.z * -8 + 8;
  r0.z = sqrt(r0.z);
  r0.z = max(0.001000, r0.z);
  r0.xy = r0.xy / r0.zz;
  o2.xy = float2(0.5,0.5) + r0.xy;
  o1.zw = float2(0,1);
  o2.z = 0;
  return;
}