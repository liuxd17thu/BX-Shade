// Author: BarricadeMKXX
// 2023-09-02
// Working in progress
// License: TBD

#include "Reshade.fxh"
#include "ffxiv_common.fxh"

#define DEG_OF_PI 57.2957795

uniform bool bCKEnable<
    ui_category = "Chromakey#1";
> = true;

uniform float2 fCKBase<
    ui_type = "slider";
    ui_category = "Chromakey#1";
    ui_min = 0; ui_max = 1;
    ui_label = "Base Point";
> = float2(0.5f, 0.5f);

uniform bool bCKFreeze<
    ui_category = "Chromakey#1";
> = false;

uniform float fCKTheta<
    ui_type = "slider";
    ui_category = "Chromakey#1";
    ui_min = -180; ui_max = 180; ui_step = 1;
    ui_label = "Rotate";
> = 0f;

uniform float fCKPhi<
    ui_type = "slider";
    ui_category = "Chromakey#1";
    ui_min = -90; ui_max = 90; ui_step = 1;
    ui_label = "Up & Down";
> = 0f;

uniform float3 fCKColor<
    ui_type = "color";
    ui_category = "Chromakey#1";
    ui_min = 0; ui_max = 1;
    ui_label = "Color";
> = float3(0.29, 0.84, 0.36);

uniform float fCKZOffset<
    ui_type = "drag";
    ui_category = "Chromakey#1";
    ui_step = 0.1;
    ui_label = "Z offset";
> = 0.0f;

uniform float fCKZOffsetScale<
    ui_type = "drag";
    ui_category = "Chromakey#1";
    ui_step = 1;
    ui_units = "x";
    ui_label = "Z offset Scale";
> = 1000;

uniform bool bCK2Enable<
    ui_category = "Chromakey#2";
> = false;

uniform float2 fCK2Base<
    ui_type = "slider";
    ui_category = "Chromakey#2";
    ui_min = 0; ui_max = 1;
    ui_label = "Base Point";
> = float2(0.5f, 0.5f);

uniform bool bCK2Freeze<
    ui_category = "Chromakey#2";
> = false;

uniform float fCK2Theta<
    ui_type = "slider";
    ui_category = "Chromakey#2";
    ui_min = -180; ui_max = 180; ui_step = 1;
    ui_label = "Rotate";
> = 90f;

uniform float fCK2Phi<
    ui_type = "slider";
    ui_category = "Chromakey#2";
    ui_min = -90; ui_max = 90; ui_step = 1;
    ui_label = "Up & Down";
> = 0f;

uniform float3 fCK2Color<
    ui_type = "color";
    ui_category = "Chromakey#2";
    ui_min = 0; ui_max = 1;
    ui_label = "Color";
> = float3(0.07, 0.18, 0.72);

uniform float fCK2ZOffset<
    ui_type = "drag";
    ui_category = "Chromakey#2";
    ui_step = 0.1;
    ui_label = "Z offset";
> = 0.0f;

uniform float fCK2ZOffsetScale<
    ui_type = "drag";
    ui_category = "Chromakey#2";
    ui_step = 1;
    ui_units = "x";
    ui_label = "Z offset Scale";
> = 1000;

// uniform int iScreenDBG<
//     ui_type = "combo";
//     ui_min = 0; ui_max = 2;
//     ui_category = "Wall";
//     ui_items = "xy\0yz\0zx\0";
// > = 0;

uniform bool bDebug = true;
uniform float fDebug_VertOff<
    ui_type = "drag";
    ui_step = 1;
> = 0;
uniform float fDebug_R<
    ui_type = "drag";
    ui_step = 1;
> = 10;

texture texWorldBase{ Width = 1; Height=2; Format = RGBA32F; };
sampler sampWorldBase { Texture = texWorldBase; };
storage2D wWorldBase { Texture = texWorldBase; };

float GetDepth(float2 texcoords)
{
    return tex2Dlod(ReShade::DepthBuffer, float4(texcoords, 0, 0)).x;
}

int CheckPlaneFrontBack(float3 PlaneBase, float3 normal, float3 Point)
{
    return sign(dot(PlaneBase - Point, normal));
}

void SetChromakeyPosCS(uint3 id : SV_DispatchThreadID)
{
    float4 prev = tex2Dfetch(sampWorldBase, int2(0,id.y));
    bool CKFreeze[2] = {bCKFreeze, bCK2Freeze};
    float2 CKBase[2] = {fCKBase, fCK2Base};
    float3 CKBaseInWorld = FFXIV::get_world_position_from_uv(CKBase[id.y], GetDepth(CKBase[id.y]));

    if(!CKFreeze[id.y])
        tex2Dstore(wWorldBase, id.xy, float4(CKBaseInWorld, 1));

    // if(texcoords.y < 0.5)
    //     worldPos = bCKFreeze ? prev : float4(CKBaseInWorld, 0);
    // else
    //     worldPos = bCK2Freeze ? prev2 : float4(CK2BaseInWorld, 0);
}

float3 DrawChromakey(float4 pos : SV_POSITION, float2 texcoords : TEXCOORD) : SV_TARGET
{
    float3 Screen[2] = { fCKColor, fCK2Color };
    float4 worldPos = float4(FFXIV::get_world_position_from_uv(texcoords, GetDepth(texcoords)), 1);
    float3 direction = float3(sin(fCKTheta / DEG_OF_PI) * cos(fCKPhi / DEG_OF_PI), -cos(fCKTheta / DEG_OF_PI) * cos(fCKPhi / DEG_OF_PI), -sin(fCKPhi / DEG_OF_PI));
    float3 direction2 = float3(sin(fCK2Theta / DEG_OF_PI) * cos(fCK2Phi / DEG_OF_PI), -cos(fCK2Theta / DEG_OF_PI) * cos(fCK2Phi / DEG_OF_PI), -sin(fCK2Phi / DEG_OF_PI));

    float3 camPos = FFXIV::camPos;
    float3 CKBaseInWorld = tex2Dfetch(sampWorldBase, int2(0,0)).xyz;
    float3 CK2BaseInWorld = tex2Dfetch(sampWorldBase, int2(0,1)).xyz;
    
    // FFXIV needs to use xzy, too weird
    int fb = CheckPlaneFrontBack(CKBaseInWorld + float3(0, 0, (abs(fCKPhi)==90) * fCKZOffset * fCKZOffsetScale), direction.xzy, worldPos.xyz);
    int fb2 = CheckPlaneFrontBack(CK2BaseInWorld + float3(0, 0, (abs(fCK2Phi)==90) * fCK2ZOffset * fCK2ZOffsetScale), direction2.xzy, worldPos.xyz);
    //int fb = CheckPlaneFrontBack(CKBaseInWorld, direction.xzy, worldPos.xyz);

    float2 offset = (texcoords - FFXIV::get_uv_from_world_position(CKBaseInWorld).xy) / ReShade::PixelSize;
    float2 offset2 = (texcoords - FFXIV::get_uv_from_world_position(CK2BaseInWorld).xy) / ReShade::PixelSize;

    float3 res = (tex2D(ReShade::BackBuffer, texcoords).rgb);

    if(bCKEnable && fb <= 0){
        res = Screen[0];
        if(bCK2Enable && fb2 <= 0)
            res = (res + Screen[1]) * 0.5;
    }
    else if(bCK2Enable && fb2 <= 0)
        res = Screen[1];

    if(bDebug && bCKEnable && length(offset) < fDebug_R)
        res = float3(0,ReShade::GetLinearizedDepth(texcoords),0);
    if(bDebug && bCK2Enable && length(offset2) < fDebug_R)
        res = float3(0,0,ReShade::GetLinearizedDepth(texcoords));
    return res;
}

technique BX_XIVChromakeyPlus
<
    ui_label = "BX_XIVChromakeyPlus";
>
{
    pass passGenPos{
        ComputeShader = SetChromakeyPosCS<1, 2>;
        DispatchSizeX = 1;
        DispatchSizeY = 1;
    }
    pass passDraw{
        VertexShader = PostProcessVS;
        PixelShader = DrawChromakey;
    }
}