// Author: BarricadeMKXX
// 2023-09-04
// Working in progress
// License: TBD

#include "Reshade.fxh"
#include "ffxiv_common.fxh"
#include "BX_Multilingual.fxh"

#define DEG_OF_PI 57.2957795

uniform bool bDebug<
    LABEL("Show Chromakey Pivot", "显示幕布基点")
    TOOLTIP("Remember to disable this when taking a screenshot.", "记得截图时关掉这个。")
> = true;

uniform float fDebug_R<
    LABEL("Pivot Radius", "基点半径")
    ui_type = "drag";
    ui_step = 1;
> = 10;

uniform bool bAlpha<
    LABEL("Alpha Transparency", "透明度抠像")
    TOOLTIP("You also need to untick the \"Clear Alpha Channel\" in ReShade/GShade's Settings tab.", \
            "同时需要在ReShade/GShade设置页关闭“清除Alpha通道”功能。")
> = false;

uniform float fCKGradient<
    ui_type = "drag";
    LABEL("Chromakey Gradient", "幕布渐变")
    TOOLTIP("Smooth the intersection between chromakey and scene.", "平滑幕布与场景相交的位置。")
    ui_min = 0; ui_max = 0.5;
    ui_step = 0.0001;
> = 0.0;

uniform bool bCKEnable<
    CATEGORY("Chromakey #1", "幕布 #1")
    LABEL("Enable This Chromakey", "启用此幕布")
> = true;

uniform float2 fCKBase<
    ui_type = "slider";
    CATEGORY("Chromakey #1", "幕布 #1")
    ui_min = 0; ui_max = 1;
    LABEL("Base Point", "基点")
    TOOLTIP("Set the position of base point in screen space.\nYou can still rotate the chromakey.", \
            "设定幕布基点在屏幕空间中的位置。\n冻结后仍然可以旋转幕布。")
> = float2(0.5f, 0.5f);

uniform bool bCKFreeze<
    CATEGORY("Chromakey #1", "幕布 #1")
    LABEL("Freeze", "冻结基点")
    TOOLTIP("Freeze the base point into world space.", "将幕布基点冻结于游戏世界空间中。")
> = false;

uniform float fCKTheta<
    ui_type = "slider";
    CATEGORY("Chromakey #1", "幕布 #1")
    ui_min = -180; ui_max = 180; ui_step = 1;
    ui_units = "°";
    LABEL("Rotate Horizontally", "水平旋转")
    TOOLTIP("Rotate the chromakey about the vertical axis goes through the base point.", "围绕过基点的竖直轴旋转幕布。")
> = 0f;

uniform float fCKPhi<
    ui_type = "slider";
    CATEGORY("Chromakey #1", "幕布 #1")
    ui_min = -90; ui_max = 90; ui_step = 1;
    ui_units = "°";
    LABEL("Rotate Vertically", "俯仰旋转")
    TOOLTIP("Rotate the chromakey up and down.", "上下旋转幕布。")
> = 0f;

uniform float3 fCKColor<
    ui_type = "color";
    CATEGORY("Chromakey #1", "幕布 #1")
    ui_min = 0; ui_max = 1;
    LABEL("Chromakey Color", "幕布颜色")
> = float3(0.29, 0.84, 0.36);

uniform float fCKZOffset<
    ui_type = "drag";
    CATEGORY("Chromakey #1", "幕布 #1")
    ui_step = 0.1;
    LABEL("Z Offset", "Z轴修正")
    TOOLTIP("Shift the chromakey slightly, to reduce the flickers / zebra lines / half opacity when keying the floor.\nOnly available when `Rotate Vertically` = 90 or -90.", \
            "微调幕布位置，减少抠像地板时出现的闪烁/条纹/半透明。\n仅在`俯仰旋转`设为正负90时有效。")
> = 0.0f;

uniform float fCKZOffsetScale<
    ui_type = "drag";
    CATEGORY("Chromakey #1", "幕布 #1")
    ui_step = 1;
    ui_units = "x";
    LABEL("Z Offset Scale", "Z轴修正倍率")
    TOOLTIP("Multiplier for `Z Offset`, usually 1000x is OK.", \
            "`Z轴修正`的倍率，一般1000倍即可。")
> = 1000;

uniform bool bCK2Enable<
    CATEGORY("Chromakey #2", "幕布 #2")
    LABEL("Enable This Chromakey", "启用此幕布")
> = false;

uniform float2 fCK2Base<
    ui_type = "slider";
    CATEGORY("Chromakey #2", "幕布 #2")
    ui_min = 0; ui_max = 1;
    LABEL("Base Point", "基点")
    TOOLTIP("Set the position of base point in screen space.\nYou can still rotate the chromakey.", \
            "设定幕布基点在屏幕空间中的位置。\n冻结后仍然可以旋转幕布。")    
> = float2(0.5f, 0.5f);

uniform bool bCK2Freeze<
    CATEGORY("Chromakey #2", "幕布 #2")
    LABEL("Freeze", "冻结基点")
    TOOLTIP("Freeze the base point into world space.", "将幕布基点冻结于游戏世界空间中。")
> = false;

uniform float fCK2Theta<
    ui_type = "slider";
    CATEGORY("Chromakey #2", "幕布 #2")
    ui_min = -180; ui_max = 180; ui_step = 1;
    ui_units = "°";
    LABEL("Rotate Horizontally", "水平旋转")
    TOOLTIP("Rotate the chromakey about the vertical axis goes through the base point.", "围绕过基点的竖直轴旋转幕布。")
> = 90f;

uniform float fCK2Phi<
    ui_type = "slider";
    CATEGORY("Chromakey #2", "幕布 #2")
    ui_min = -90; ui_max = 90; ui_step = 1;
    ui_units = "°";
    LABEL("Rotate Vertically", "俯仰旋转")
    TOOLTIP("Rotate the chromakey up and down.", "上下旋转幕布。")
> = 0f;

uniform float3 fCK2Color<
    ui_type = "color";
    CATEGORY("Chromakey #2", "幕布 #2")
    ui_min = 0; ui_max = 1;
    LABEL("Chromakey Color", "幕布颜色")
> = float3(0.07, 0.18, 0.72);

uniform float fCK2ZOffset<
    ui_type = "drag";
    CATEGORY("Chromakey #2", "幕布 #2")
    ui_step = 0.1;
    LABEL("Z Offset", "Z轴修正")
    TOOLTIP("Shift the chromakey slightly, to reduce the flickers / zebra lines / half opacity when keying the floor.\nOnly available when `Rotate Vertically` = 90 or -90.", \
            "微调幕布位置，减少抠像地板时出现的闪烁/条纹/半透明。\n仅在`俯仰旋转`设为正负90时有效。")
> = 0.0f;

uniform float fCK2ZOffsetScale<
    ui_type = "drag";
    CATEGORY("Chromakey #2", "幕布 #2")
    ui_step = 1;
    ui_units = "x";
    LABEL("Z Offset Scale", "Z轴修正倍率")
    TOOLTIP("Multiplier for `Z Offset`, usually 1000x is OK.", \
            "`Z轴修正`的倍率，一般1000倍即可。")
> = 1000;

// uniform int iScreenDBG<
//     ui_type = "combo";
//     ui_min = 0; ui_max = 2;
//     ui_category = "Wall";
//     ui_items = "xy\0yz\0zx\0";
// > = 0;

texture texWorldBase{ Width = 1; Height=2; Format = RGBA32F; };
sampler sampWorldBase { Texture = texWorldBase; };
storage2D wWorldBase { Texture = texWorldBase; };

float GetDepth(float2 texcoords)
{
    return tex2Dlod(ReShade::DepthBuffer, float4(texcoords, 0, 0)).x;
}

float CheckPlaneFrontBack(float3 PlaneBase, float3 normal, float3 Point)
{
    return dot(PlaneBase - Point, normal);
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

float4 DrawChromakey(float4 pos : SV_POSITION, float2 texcoords : TEXCOORD) : SV_TARGET
{
    float4 Screen[2] = { float4(fCKColor, 1), float4(fCK2Color, 1) };
    float4 worldPos = float4(FFXIV::get_world_position_from_uv(texcoords, GetDepth(texcoords)), 1);
    float3 direction = float3(sin(fCKTheta / DEG_OF_PI) * cos(fCKPhi / DEG_OF_PI), -cos(fCKTheta / DEG_OF_PI) * cos(fCKPhi / DEG_OF_PI), -sin(fCKPhi / DEG_OF_PI));
    float3 direction2 = float3(sin(fCK2Theta / DEG_OF_PI) * cos(fCK2Phi / DEG_OF_PI), -cos(fCK2Theta / DEG_OF_PI) * cos(fCK2Phi / DEG_OF_PI), -sin(fCK2Phi / DEG_OF_PI));

    float3 camPos = FFXIV::camPos;
    float3 CKBaseInWorld = tex2Dfetch(sampWorldBase, int2(0,0)).xyz;
    float3 CK2BaseInWorld = tex2Dfetch(sampWorldBase, int2(0,1)).xyz;
    
    // FFXIV needs to use xzy, too weird
    float fb = CheckPlaneFrontBack(CKBaseInWorld + float3(0, 0, (abs(fCKPhi)==90) * fCKZOffset * fCKZOffsetScale), direction.xzy, worldPos.xyz);
    float fb2 = CheckPlaneFrontBack(CK2BaseInWorld + float3(0, 0, (abs(fCK2Phi)==90) * fCK2ZOffset * fCK2ZOffsetScale), direction2.xzy, worldPos.xyz);
    //float fb = CheckPlaneFrontBack(CKBaseInWorld, direction.xzy, worldPos.xyz);

    float2 offset = (texcoords - FFXIV::get_uv_from_world_position(CKBaseInWorld).xy) / ReShade::PixelSize;
    float2 offset2 = (texcoords - FFXIV::get_uv_from_world_position(CK2BaseInWorld).xy) / ReShade::PixelSize;

    float4 res = float4(tex2D(ReShade::BackBuffer, texcoords).rgb, 1.0);

    // mask : 0 = chromakey screen, 1 = image
    float2 mask = float2(smoothstep(-fCKGradient, fCKGradient, fb), smoothstep(-fCKGradient, fCKGradient, fb2));
    if(!bCKEnable){
        mask.x = 1.0;
        // res = bAlpha    ? lerp(0, res, mask.x)
        //                 : lerp(Screen[0], res, mask.y);
    }
    if(!bCK2Enable){
        mask.y = 1.0;
        // res = bAlpha    ? lerp(0, res, mask.y)
        //                 : lerp(Screen[1], res, mask);
    }

    if(bAlpha)
        res = lerp(0, res, min(mask.x, mask.y));
    else{
        res = lerp(lerp(Screen[1], Screen[0], (1 + mask.y - mask.x) / 2), res, min(mask.x, mask.y));
    }

    if(bDebug && bCKEnable && length(offset) < fDebug_R)
        res = float4(0.5, 1, 0.5, 1);
    if(bDebug && bCK2Enable && length(offset2) < fDebug_R)
        res = float4(0.5, 0.5, 1, 1);
    return res;
}

technique BX_XIVChromakeyPlus
<
    LABEL("BX_XIVChromakeyPlus - Alpha", "BX::XIV色键抠像增强(测试版)[BX_XIVChromakeyPlus]")
    TOOLTIP( \
        "!!! THIS SHADER NEEDS REST ADDON & FFXIV SPECIFIC CONFIG TO WORK !!!\n" \
        "Advanced chromakey, allowing you to set 2 chromakeys in the *game world space*, adjust direction and pin them!\n" \
        "Author: BarricadeMKXX, License: (TBD)\n" \
        "Credits to Alex (4lex4nder) for his REST addon and ffxiv configuration!" \
        , \
        "!!！本着色器需要REST插件及FF14特化配置文件方可正常使用 !!!\n" \
        "高级版色键抠像，允许在*游戏世界空间中*设置两个绿幕，调节朝向并固定它们！\n" \
        "作者：路障MKXX，许可证：（待定）\n" \
        "感谢Alex (4lex4nder) 的REST插件及FF14特化配置文件。" \
    )
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