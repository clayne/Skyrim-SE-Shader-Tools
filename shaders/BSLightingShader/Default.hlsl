#define PIXELSHADER

#define SPECULAR
#define MODELSPACENORMALS
#define SOFT_LIGHTING
#define RIM_LIGHTING
#define BACK_LIGHTING

// BSLightingShader - Default Technique (ID 0)

// Supported Flags
// 1<<0 Vc      #define VC                      enforced on all pixel shader passes by renderer code
// 1<<1 Sk      #define SKINNED                        
// 1<<2 Msn     #define MODELSPACENORMALS
// 1<<9 Spc     #define SPECULAR
// 1<<10 Sss    #define SOFT_LIGHTING
// 1<<11 Rim    #define RIM_LIGHTING
// 1<<12 Bk     #define BACK_LIGHTING

#include "include/CommonDefines.hlsli"
#include "include/ConstantBuffers.hlsli"
#include "include/InputOutput.hlsli"
#include "include/Samplers.hlsli"

#include "include/Lighting.hlsl"

PS_OUTPUT PSMain(PS_INPUT input)
{
    PS_OUTPUT output;
    
    // view direction vector    
#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    float3 viewDirection = normalize(input.ViewDirectionVec);
#else
    // sometimes used for calculations when there's no actual view direction
    float3 viewDirection = normalize(float3(1, 1, 1));
#endif
    
    // diffuse texture   
    float4 diffuseSample = Sample2D(Diffuse, input.TexCoords.xy).xyzw;
    float3 diffuseColour = diffuseSample.xyz;
    float  diffuseAlpha = diffuseSample.w;
    
    // normal texture and specular power
#if defined(MODELSPACENORMALS)
    float3 normalSample = Sample2D(Normal, input.TexCoords.xy).xyz;
    float  specularPower = Sample2D(Specular, input.TexCoords.xy).x;
#else
    float4 normalSample = Sample2D(Normal, input.TexCoords.xy).xyzw;
    float  specularPower = normalSample.w;
#endif    
    float3 normal = normalSample.xyz * 2.0 - 1.0;
    
    // subsurface mask texture used for soft and rim lighting
#if defined(SOFT_LIGHTING) || defined(RIM_LIGHTING)
    float3 subsurfaceMaskSample = Sample2D(SubSurface, input.TexCoords.xy).xyz;
#endif    
    float cb_LightingProperty_fSubSurfaceLightRolloff = LightingEffectParams.x;
    float cb_LightingProperty_fRimLightPower = LightingEffectParams.y;
    
    // back lighting mask texture
#if defined(BACK_LIGHTING)
    float3 backlightingMaskSample = Sample2D(BackLightMask, input.TexCoords.xy).xyz;
#endif
    
    // common space normal   
#if defined(HAS_COMMON_TRANSFORM)
    float3x3 commonSpaceTransform = float3x3(input.CommonSpaceTransform0, input.CommonSpaceTransform1, input.CommonSpaceTransform2);
    float4   commonSpaceNormal = float4(normalize(mul(commonSpaceTransform, normal)), 1);
#else
    float4 commonSpaceNormal = float4(normal.xyz, 1);
#endif
    
    // vertex normal used for some flags
    // note that the common space transform is the TBN matrix
#if defined(HAS_COMMON_TRANSFORM)
    float3 vertexNormal = float3(commonSpaceTransform[0].z, commonSpaceTransform[1].z, commonSpaceTransform[2].z);
    float3 vertexNormalN = normalize(vertexNormal);
#endif
    
    float3 diffuseLighting = 0; // total diffuse lighting contribution
    
#if defined(SPECULAR)
    float3 specularLighting = 0; // total specular lighting contribution
    float specularHardness = SpecularColour.w;
#endif
    
    int totalLightCount = min(7, NumLightNumShadowLight.x);
    
    // directional light
    diffuseLighting += DirectionalLightDiffuse(DirLightDirection.xyz, DirLightColour.xyz, commonSpaceNormal.xyz);

#if defined(SOFT_LIGHTING)
    diffuseLighting += SoftLighting(DirLightDirection.xyz, DirLightColour.xyz, subsurfaceMaskSample, cb_LightingProperty_fSubSurfaceLightRolloff, commonSpaceNormal.xyz);
#endif
    
#if defined(RIM_LIGHTING)
    diffuseLighting += RimLighting(DirLightDirection.xyz, DirLightColour.xyz, subsurfaceMaskSample, cb_LightingProperty_fRimLightPower, viewDirection, commonSpaceNormal.xyz);
#endif
    
#if defined(BACK_LIGHTING)
    diffuseLighting += BackLighting(DirLightDirection.xyz, DirLightColour.xyz, backlightingMaskSample, commonSpaceNormal.xyz);
#endif
    
#if defined(SPECULAR)
    specularLighting += DirectionalLightSpecular(DirLightDirection.xyz, DirLightColour.xyz, specularHardness, viewDirection, commonSpaceNormal.xyz);
#endif
    
    
    // point lights
    for (int currentLight = 0; currentLight < totalLightCount; currentLight++)
    {
        float3 lightColour = PointLightColour[currentLight].xyz;
    
        float3 lightDirection = PointLightPosition[currentLight].xyz - input.CommonSpaceVertexPos.xyz;
        float lightRadius = PointLightPosition[currentLight].w;
        float lightAttenuation = 1 - pow(saturate(length(lightDirection) / lightRadius), 2);
        float3 lightDirectionN = normalize(lightDirection);
        float3 lightDiffuseLighting = DirectionalLightDiffuse(lightDirectionN, lightColour, commonSpaceNormal.xyz);
        
#if defined(SOFT_LIGHTING)
        lightDiffuseLighting += SoftLighting(lightDirection, lightColour, subsurfaceMaskSample, cb_LightingProperty_fSubSurfaceLightRolloff, commonSpaceNormal.xyz);
#endif
        
#if defined(RIM_LIGHTING)
        lightDiffuseLighting += RimLighting(lightDirectionN, lightColour, subsurfaceMaskSample, cb_LightingProperty_fRimLightPower, viewDirection, commonSpaceNormal.xyz);
#endif
        
#if defined(BACK_LIGHTING)
        diffuseLighting += BackLighting(lightDirection, lightColour, backlightingMaskSample, commonSpaceNormal.xyz);
#endif
        
        diffuseLighting += lightAttenuation * lightDiffuseLighting;
        
#if defined(SPECULAR)
        specularLighting += DirectionalLightSpecular(lightDirectionN, lightColour, specularHardness, viewDirection, commonSpaceNormal.xyz);
#endif
    }
    
    // directional ambient
    float3 directionalAmbient = float3(
        dot(DirectionalAmbient[0].xyzw, commonSpaceNormal.xyzw),
        dot(DirectionalAmbient[1].xyzw, commonSpaceNormal.xyzw),
        dot(DirectionalAmbient[2].xyzw, commonSpaceNormal.xyzw)
        );
    
    diffuseLighting += directionalAmbient.xyz;
    
    // emit colour
    diffuseLighting += EmitColour.xyz;
    
    // fake IBL
    diffuseLighting += IBLParams.yzw * IBLParams.x;
    
    float3 outDiffuse = diffuseLighting * diffuseColour * input.VertexColour.xyz;
    
    // diffuse clamping
    float gs_fLightingOutputColourClampPostLit = ColourOutputClamp.x;
    
    outDiffuse = min(outDiffuse, gs_fLightingOutputColourClampPostLit);
   
    float3 outColour = outDiffuse;    
        
    // add specular contribution
#if defined(SPECULAR)
    float cb_LightingProperty_fSpecularLODFade = MaterialData.y;
    float3 outSpecular = specularLighting * specularPower * cb_LightingProperty_fSpecularLODFade * SpecularColour.xyz;
    
    outColour += outSpecular;
    
    float gs_fLightingOutputColourClampPostSpec = ColourOutputClamp.z;
    outColour = min(outColour, gs_fLightingOutputColourClampPostSpec);
#endif    
    
    // fog
    float cb_FirstPerson = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.y;
    float cb_AlphaPass = GammaInvX_FirstPersonY_AlphaPassZ_CreationKitW.z;
    float shouldFogOutput = cb_FirstPerson * cb_AlphaPass;  
    float cb_fInvFrameBufferRange = FogColour.w;
    
    float3 fogColour = input.FogParam.xyz;
    float fogAmount = input.FogParam.w;   
    
    float3 foggedColour = lerp(outColour, fogColour, fogAmount) * cb_fInvFrameBufferRange;
    
    output.Colour.xyz = lerp(outColour, foggedColour, shouldFogOutput);
    
    // alpha
    float cb_LightingProperty_fAlpha = MaterialData.z;
    
    float outAlpha = input.VertexColour.w * cb_LightingProperty_fAlpha * diffuseAlpha;
    
    output.Colour.w = outAlpha;
    
    // motion vector
    float2 currProjPosition = float2(dot(ViewProjMatrixUnjittered[0].xyzw, input.WorldVertexPos.xyzw), dot(ViewProjMatrixUnjittered[1].xyzw, input.WorldVertexPos.xyzw)) / dot(ViewProjMatrixUnjittered[3].xyzw, input.WorldVertexPos.xyzw);
    float2 prevProjPosition = float2(dot(PreviousViewProjMatrixUnjittered[0].xyzw, input.PreviousWorldVertexPos.xyzw), dot(PreviousViewProjMatrixUnjittered[1].xyzw, input.PreviousWorldVertexPos.xyzw)) / dot(PreviousViewProjMatrixUnjittered[3].xyzw, input.PreviousWorldVertexPos.xyzw);
    float2 motionVector = (currProjPosition - prevProjPosition) * float2(-0.5, 0.5);
    
    if (SSRParams.z > 0.000010)
    {
        output.MotionVector.xy = float2(1, 0);
    }
    else
    {
        output.MotionVector.xy = motionVector.xy;
    }    
    output.MotionVector.zw = float2(0, 1);    
    
    // output normal 
    float3x3 viewSpaceTransform = float3x3(input.ViewSpaceTransform0, input.ViewSpaceTransform1, input.ViewSpaceTransform2);
    
    float3 viewSpaceNormal = normalize(mul(viewSpaceTransform, normal.xyz));
    viewSpaceNormal.z = max(0.001, sqrt(viewSpaceNormal.z * -8 + 8));
    
    output.Normal.xy = float2(0.5, 0.5) + (viewSpaceNormal.xy / viewSpaceNormal.z);
    output.Normal.z = 0;
    
    // output normal alpha stores a specular mask for use by other shaders
    float cb_SpecMaskBegin = SSRParams.x;
    float cb_SpecMaskEnd = SSRParams.y;
    float gs_fSpecularLODFade = SSRParams.w;    

    output.Normal.w = gs_fSpecularLODFade * smoothstep(cb_SpecMaskBegin - 0.000010, cb_SpecMaskEnd, specularPower);
    
    return output;
}