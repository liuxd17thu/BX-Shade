// Author: BarricadeMKXX
// 2024-07-20
// License: MIT

#if __APPLICATION__ == 0x6f24790f
    #if exists "ffxiv_common.fxh"
        #include "ffxiv_common.fxh"
    #else
        #error "XIV_StaticLayer needs REST addon and ffxiv_common.fxh to work correctly."
    #endif
#else
    #error "XIV_StaticLayer can only work with REST addon in Final Fantasy XIV (DX11)."
#endif

#define DEG_OF_PI 57.2957795

#define LOCK_ALL    0
#define LOCK_POS    1
#define UNLOCK      2

#define LAYOUT_WS_BP       0
#define LAYOUT_SCALE_XY    1
#define LAYOUT_N_VEC       2
#define LAYOUT_R_VEC       3
#define LAYOUT_U_VEC       4
#define LAYOUT_SS_C_POINT  5
#define LAYOUT_SS_R_POINT  6
#define LAYOUT_SS_UP_POINT 7

#define SLayer_Quantity_MAX 4

#ifndef SLayer_Quantity
    #define SLayer_Quantity 0
#endif

#define SLayer_Category "|\n|\n| Static Layer #"

#if SLayer_Quantity_MAX < SLayer_Quantity
    #error "Too many Static Layers!"
#endif

namespace BXCommon{
    texture2D texBXFakeZ{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = R32F;
    };
    sampler2D sampBXFakeZ{
        Texture = texBXFakeZ;
    };
    texture2D texBXBuffer{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8;
    };
    sampler2D sampBXBuffer{
        Texture = texBXBuffer;
    };
    texture2D texWorldBase {
        Width = SLayer_Quantity_MAX + 1;
        Height = 8;
        Format = RGBA32F;
    };
    sampler2D sampWorldBase { Texture = texWorldBase; };
    storage2D wWorldBase { Texture = texWorldBase; };
}

float GetDepth(float2 texcoord)
{
    return tex2Dlod(BXCommon::sampBXFakeZ, float4(texcoord, 0, 0)).x;
}
float LinearizeDepth(float x)
{
	x /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - x * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - 1.0);
    return x;
}
float DelinearizeDepth(float x)
{
    return (x * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE) / (1.0 + x * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - 1.0));
}
float3 RotateVec(float3 V, float3 Axis, float rotateRad)
{
    float3 Vrot = V * cos(rotateRad) + cross(Axis, V) * sin(rotateRad) + Axis * dot(Axis, V) * (1 - cos(rotateRad));
    return Vrot;
}
// float CheckOutOfBoundInWorldSpace(float3 A)
// {
//     return dot(A - FFXIV::get_world_position_from_uv(float2(0.5, 0.5), 1), FFXIV::camDir());
// }
float CheckDepthInWorldSpace(float3 A, float3 B)
{
#if RESHADE_DEPTH_INPUT_IS_REVERSED != 0
    return FFXIV::get_uv_from_world_position(A).z - FFXIV::get_uv_from_world_position(B).z;
#else
     return FFXIV::get_uv_from_world_position(B).z - FFXIV::get_uv_from_world_position(A).z;
#endif
}
float3 GetWSPlaneProjFromUV(const float3 PlaneBase, const float3 PlaneNormal, const float2 TexCoord)
{
    float3 wsD1 = FFXIV::get_world_position_from_uv(TexCoord.xy, 1);
    float3 wsD0 = FFXIV::camPos();
    float3 wsD = normalize(wsD0 - wsD1);
    float3 wsBD0 = wsD0 - PlaneBase;
    return wsD0 - wsD * dot(wsBD0, PlaneNormal) / dot(wsD, PlaneNormal);
}
float EncodeDepth(float z)
{
#if RESHADE_DEPTH_INPUT_IS_REVERSED != 0
    return DelinearizeDepth(1.0 - z);
#else
    return LinearizeDepth(z);
#endif
}
float DecodeDepth(float z)
{
#if RESHADE_DEPTH_INPUT_IS_REVERSED != 0
    return LinearizeDepth(1.0 - z);
#else
    return DelinearizeDepth(z);
#endif
}

#define _CAT(x,y) x ## y
#define CAT(x,y) _CAT(x,y)

#define _STR(x) #x
#define STR(x) _STR(x)

#define SLayer_SUMMON(ID, SLayer_Name, SLayer_SizeX, SLayer_SizeY) \
uniform int CAT(iLayerID_, ID)< \
    ui_label = "Lock Status"; \
    ui_type = "combo"; \
    ui_items = "Lock Pos & Dir\0Lock Pos\0Unlock\0"; \
    ui_category = SLayer_Category STR(ID); \
> = 2; \
\
uniform float2 CAT(fLayerBaseXY_, ID)< \
    ui_label = "Base Point | XY"; \
    ui_type = "slider"; \
    ui_min = 0; ui_max = 1; \
    ui_category = SLayer_Category STR(ID); \
> = float2(0.5f, 0.5f); \
\
uniform bool CAT(bDepth_, ID)< \
    ui_label = "Get Depth of Scene Objects"; \
    ui_category = SLayer_Category STR(ID); \
> = false; \
\
uniform float CAT(fLayerBaseZ_, ID)< \
    ui_label = "Base Point | Z"; \
    ui_type = "slider"; \
    ui_min = 0.02; ui_max = 1; ui_step = 0.000001; \
    ui_category = SLayer_Category STR(ID); \
> = 0.1f; \
\
uniform bool CAT(bInfinite_, ID)< \
    ui_label = "Infinite"; \
    ui_category = SLayer_Category STR(ID); \
> = false; \
\
uniform float2 CAT(fUVOffset_, ID)< \
    ui_label = "UV Offset"; \
    ui_type = "drag"; \
    ui_step = 0.01; \
    ui_category = SLayer_Category STR(ID); \
> = float2(0.0f, 0.0f); \
\
uniform bool CAT(bClamp_, ID)< \
    ui_label = "Clamp Border"; \
    ui_category = SLayer_Category STR(ID); \
> = false; \
\
uniform float CAT(fScale_, ID)< \
    ui_label = "Scale H&V"; \
    ui_type = "slider"; \
    ui_min = 0; ui_max = 5; \
    ui_category = SLayer_Category STR(ID); \
> = 1.0f; \
\
uniform float2 CAT(fScaleHV_, ID)< \
    ui_label = "Scale H/V"; \
    ui_type = "slider"; \
    ui_min = 0; ui_max = 5; \
    ui_category = SLayer_Category STR(ID); \
> = float2(1.0f, 1.0f); \
\
uniform float CAT(fOpacity_, ID)< \
    ui_label = "Opacity"; \
    ui_type = "slider"; \
    ui_min = 0; ui_max = 1; \
    ui_category = SLayer_Category STR(ID); \
> = 1.0f; \
\
uniform float3 CAT(fRotDeg_, ID)< \
    ui_label = "Rotate"; \
    ui_type = "slider"; \
    ui_min = -180; ui_max = 180; ui_step = 0.1; \
    ui_units = "°"; \
    ui_category = SLayer_Category STR(ID); \
> = float3(0, 0, 0); \
\
uniform bool CAT(bPanel_, ID) < source = "overlay_open"; >; \
\
texture2D CAT(texSLayerTex_, ID)< source = SLayer_Name; > { \
    Width = SLayer_SizeX; \
    Height = SLayer_SizeY; \
    Format = RGBA8; \
}; \
sampler CAT(sampSLayerTex_, ID){ \
    Texture = CAT(texSLayerTex_, ID); \
    AddressU = WRAP; \
    AddressV = WRAP; \
}; \
sampler CAT(sampSLayerCTex_, ID){ \
    Texture = CAT(texSLayerTex_, ID); \
    AddressU = CLAMP; \
    AddressV = CLAMP; \
}; \
texture2D CAT(texSL1B_, ID){ \
    Width = BUFFER_WIDTH; \
    Height = BUFFER_HEIGHT; \
    Format = RGBA8; \
}; \
sampler CAT(sampSLB_, ID){ \
    Texture = CAT(texSL1B_, ID); \
}; \
texture2D CAT(texSL1Z_, ID){ \
    Width = BUFFER_WIDTH; \
    Height = BUFFER_HEIGHT; \
    Format = R32F; \
}; \
sampler CAT(sampSLZ_, ID){ Texture = CAT(texSL1Z_, ID); }; \
\
void CAT(SetLayerPosCS_, ID)(uint3 id : SV_DispatchThreadID) \
{ \
    float depth = CAT(bDepth_, ID) ? GetDepth(CAT(fLayerBaseXY_, ID)) : DecodeDepth(CAT(fLayerBaseZ_, ID)); \
    float3 prevBasePoint = tex2Dfetch(BXCommon::wWorldBase, int2(ID-1, LAYOUT_WS_BP)).xyz; \
    float3 basePoint = CAT(iLayerID_, ID) == UNLOCK ? FFXIV::get_world_position_from_uv(CAT(fLayerBaseXY_, ID), depth).xyz : prevBasePoint; \
    float2 pixelSize = BUFFER_PIXEL_SIZE; \
    float2 scaleXY; \
    scaleXY = 0.5 * float2(SLayer_SizeX * pixelSize.x, SLayer_SizeY * pixelSize.y); \
\
    float3 wsCenter = FFXIV::get_world_position_from_uv(float2(0.5, 0.5), DecodeDepth(0.1)); \
    scaleXY.x = length(FFXIV::get_world_position_from_uv(0.5 + float2(scaleXY.x, 0), DecodeDepth(0.1)) - wsCenter); \
    scaleXY.y = length(FFXIV::get_world_position_from_uv(0.5 + float2(0, scaleXY.y), DecodeDepth(0.1)) - wsCenter); \
    scaleXY *= CAT(fScale_, ID) * CAT(fScaleHV_, ID).xy; \
\
    float3 fRotRad = (CAT(fRotDeg_, ID) / DEG_OF_PI).zxy; \
    float sAlpha, cAlpha; sincos(fRotRad.x, sAlpha, cAlpha); \
    float sBeta, cBeta; sincos(fRotRad.y, sBeta, cBeta); \
    float sGamma, cGamma; sincos(fRotRad.z, sGamma, cGamma); \
\
    float3 normalVec = float3(cAlpha*cGamma, sAlpha*cGamma, sGamma); \
    float3 rightVec = RotateVec(float3(-sGamma*cAlpha, -sGamma*sAlpha, cGamma), normalVec, fRotRad.y); \
    float3 upVec = RotateVec(float3(sAlpha, -cAlpha, 0), normalVec, fRotRad.y); \
\
    float3 ssUpPoint = FFXIV::get_uv_from_world_position(basePoint + scaleXY.y * upVec); \
    float3 ssRightPoint = FFXIV::get_uv_from_world_position(basePoint + scaleXY.x * rightVec); \
    float3 ssCenterPoint = FFXIV::get_uv_from_world_position(basePoint.xyz); \
\
    if(CAT(iLayerID_, ID) == UNLOCK){ \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_WS_BP      ), float4(basePoint.xyz, CAT(bInfinite_, ID) ? 1 : -1)); \
    } \
    tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_SCALE_XY   ), float4(scaleXY.xy, 1, 1)); \
    if(CAT(iLayerID_, ID) != LOCK_ALL){ \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_N_VEC      ), float4(normalVec.xyz, 1)); \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_R_VEC      ), float4(rightVec.xyz, 1)); \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_U_VEC      ), float4(upVec.xyz, 1)); \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_SS_C_POINT ), float4(ssCenterPoint.xyz, 1)); \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_SS_R_POINT ), float4(ssRightPoint.xyz, 1)); \
        tex2Dstore(BXCommon::wWorldBase, int2(ID-1, LAYOUT_SS_UP_POINT), float4(ssUpPoint.xyz, 1)); \
    } \
} \
\
void CAT(PS_EndPass_, ID)(float4 pos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 B : SV_TARGET0, out float Z : SV_TARGET1) \
{ \
    B = tex2D(CAT(sampSLB_, ID), texcoord).rgba; \
    Z = tex2D(CAT(sampSLZ_, ID), texcoord).x; \
} \
\
void CAT(DrawPS_, ID)(float4 position : SV_POSITION, float2 texcoord : TEXCOORD, out float4 col : SV_TARGET0, out float depth : SV_TARGET1) \
{ \
    col = tex2D(BXCommon::sampBXBuffer, texcoord.xy).rgba; \
    depth = GetDepth(texcoord.xy); \
    float3 wsPixel = FFXIV::get_world_position_from_uv(texcoord.xy, depth); \
\
    float3 basePoint; float3 scaleXY; \
    float3 normalVec, upVec, rightVec; \
    float3 ssCenterPoint, ssUpPoint, ssRightPoint; \
\
    scaleXY         = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_SCALE_XY   )).xyz; \
    basePoint       = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_WS_BP      )).xyz; \
    normalVec       = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_N_VEC      )).xyz; \
    rightVec        = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_R_VEC      )).xyz; \
    upVec           = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_U_VEC      )).xyz; \
    ssCenterPoint   = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_SS_C_POINT )).xyz; \
    ssUpPoint       = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_SS_R_POINT )).xyz; \
    ssRightPoint    = tex2Dfetch(BXCommon::sampWorldBase, int2(ID-1, LAYOUT_SS_UP_POINT)).xyz; \
\
    float3 wsProj = GetWSPlaneProjFromUV(basePoint, normalVec, texcoord.xy); \
    float2 PlaneUV = float2(dot(wsProj - basePoint, rightVec), dot(wsProj - basePoint, upVec)) / scaleXY - CAT(fUVOffset_, ID); \
\
    if(CAT(bInfinite_, ID) || all(PlaneUV.xy >= -1 && PlaneUV.xy <= 1)) \
    { \
        float4 layerColor;\
        if(CAT(bClamp_, ID)) \
            layerColor = tex2D(CAT(sampSLayerCTex_, ID), float2(0.5, 0.5) + PlaneUV * 0.5);\
        else \
            layerColor = tex2D(CAT(sampSLayerTex_, ID), float2(0.5, 0.5) + PlaneUV * 0.5); \
        if(FFXIV::get_uv_from_world_position(wsProj).z > 0 && FFXIV::get_uv_from_world_position(wsProj).z < 1) \
        { \
            float depth_check = CheckDepthInWorldSpace(wsPixel, wsProj); \
            if(depth_check < 0 || (bInverse ? 1.0 - GetDepth(texcoord.xy) : GetDepth(texcoord.xy)) >= DelinearizeDepth(fSkyDepth)) \
            { \
                col.rgb = lerp(col.rgb, layerColor.rgb, layerColor.a * CAT(fOpacity_, ID)); \
                col.a = 1.0; \
                wsPixel = wsProj; \
                if(layerColor.a == 1) \
                    depth = FFXIV::get_uv_from_world_position(wsProj).z; \
            } \
        } \
    } \
    if(CAT(bPanel_, ID) && CAT(iLayerID_, ID) != LOCK_ALL){ \
        if(all(length((ssUpPoint.xy - texcoord.xy) / BUFFER_PIXEL_SIZE) < fDotSize)){ \
            col = ssUpPoint.z <= depth ? float4(1, 1, 0, 1) : float4(0, 0, 1, 1); \
        } \
        if(all(length((ssRightPoint.xy - texcoord.xy) / BUFFER_PIXEL_SIZE) < fDotSize)){ \
            col = ssRightPoint.z <= depth ? float4(0, 1, 1, 1) : float4(1, 0, 0, 1); \
        } \
        if(all(length((ssCenterPoint.xy - texcoord.xy) / BUFFER_PIXEL_SIZE) < 2 * fDotSize)) \
        { \
            col = ssCenterPoint.z <= depth ? float4(1, 0, 1, 1) : float4(0, 1, 0, 1); \
        } \
    } \
} \
\
technique CAT(BX_XIV_StaticLayer, ID) \
{ \
    pass pSetLayerPos{ \
        ComputeShader = CAT(SetLayerPosCS_, ID)<1, 1>; \
        DispatchSizeX = 1; \
        DispatchSizeY = 1; \
    } \
    pass pDrawLayer{ \
        VertexShader = PostProcessVS; \
        PixelShader = CAT(DrawPS_, ID); \
        RenderTarget0 = CAT(texSL1B_, ID); \
        RenderTarget1 = CAT(texSL1Z_, ID); \
    } \
    pass pEnd{ \
        VertexShader = PostProcessVS; \
        PixelShader = CAT(PS_EndPass_, ID); \
        RenderTarget0 = BXCommon::texBXBuffer; \
        RenderTarget1 = BXCommon::texBXFakeZ; \
    } \
}