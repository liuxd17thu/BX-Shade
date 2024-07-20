// LUT shader loading a custom .cube 1D LUT
// Author: BarricadeMKXX
// 2024-01-15
// License: MIT
// Credits to Marty McFly's LUT shader!

#include "ReShade.fxh"

#if __RESHADE__ < 60000
    #error "该ReShade版本不支持.cube格式的LUT文件，请升级到ReShade 6.0.0或以上。"
#endif

uniform int __GUIDE<
    ui_type = "radio";
    ui_label = " ";
    ui_category = "3D Cube LUT导入说明";
    ui_text =   "！该着色器专用于加载3D的cube文件，1D LUT请使用CubeLUT1D.fx！\n"
                "导入自定义cube文件：\n"
                "1. 将cube文件置于ReShade的纹理搜索路径下，通常为 \"前面一堆/reshade-shaders/Textures/\"\n"
                "2. 在 SOURCE_CUBELUT1D_FILE 处填入该文件的文件名\n"
                "3. 在 CUBE_3D_SIZE 处填入该cube文件的尺寸，通常是16/17/32/33/64/65之一\n"
                "3? 但如果你不确定：\n"
                "  使用记事本等工具打开cube文件，开头几行中找到LUT_3D_SIZE，其后的数字就是尺寸值\n"
                "  数值错误会导致画面立刻黑屏！\n"
    ;
    ui_category_closed = true;
>;

uniform int iSample_Mode<
    ui_type = "combo";
    ui_label = "采样模式";
    ui_items = "ReShade内置\0三线性\0四面体\0";
> = 1;

uniform float fLUT_Intensity <
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT强度";
    ui_tooltip = "LUT效果的总体强度";
> = 1.00;

uniform float fLUT_AmountChroma <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT色度数量";
    ui_tooltip = "LUT改变颜色的强度。";
> = 1.00;

uniform float fLUT_AmountLuma <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT亮度数量";
    ui_tooltip = "LUT中改变亮度的强度。";
> = 1.00;

#ifndef SOURCE_CUBELUT_FILE
    #define SOURCE_CUBELUT_FILE "Neutral33-3D.cube"
#endif

#ifndef CUBE_3D_SIZE
    #define CUBE_3D_SIZE 33
#endif

texture3D texCube3D < source = SOURCE_CUBELUT_FILE; >
{
    Width = CUBE_3D_SIZE;
    Height = CUBE_3D_SIZE;
    Depth = CUBE_3D_SIZE;
    Format = RGBA32F;
};

sampler3D sampCube3D
{
    Texture = texCube3D;
    AddressU = CLAMP;
    AddressV = CLAMP;
    AddressW = CLAMP;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
};

float3 Cube3D_Triliniar(sampler3D cube, float3 in_color, int cube_size)
{
    in_color = saturate(in_color) * (cube_size - 1);
    int3 indices[2] = { int3(floor(in_color).xyz), int3(ceil(in_color).xyz) };
    float3 q = in_color - indices[0];

    float3 p[8];
    for(int i = 0; i < 8; ++i)
    {
        p[i] = tex3Dfetch(cube, int3(indices[(i>>2)&1].x, indices[(i>>1)&1].y, indices[i&1].z)).xyz;
    }
    return lerp(
                lerp(lerp(p[0], p[1], q.z), lerp(p[2], p[3], q.z), q.y),
                lerp(lerp(p[4], p[5], q.z), lerp(p[6], p[7], q.z), q.y),
            q.x);
}

float3 Cube3D_Tetrahedral(sampler3D cube, float3 in_color, int cube_size)
{
    in_color = saturate(in_color) * (cube_size - 1);
    int3 indices[2] = { int3(floor(in_color).xyz), int3(ceil(in_color).xyz) };
    float3 q = in_color - indices[0];
    int3 comp1 = q.xyz > q.yzx;
    int3 comp2 = (1 - comp1).zxy;

    const float3 p_max = tex3Dfetch(cube, indices[0] + comp1).xyz;
    const float3 p_min = tex3Dfetch(cube, indices[0] + comp2).xyz;
    const float3 p_000 = tex3Dfetch(cube, indices[0]).xyz;
    const float3 p_111 = tex3Dfetch(cube, indices[1]).xyz;

    const float3 v_111 = q - float3(1,1,1);
    const float3 v_max = q - comp1;
    const float3 v_min = q - comp2;
    const float3 v_000 = q;

    float4 weight = float4(
        1,
        abs(dot(cross(v_000, v_min), v_111)),
        abs(dot(cross(v_000, v_max), v_111)),
        abs(dot(cross(v_min, v_max), v_111))
    );

    weight.x -= dot(weight.yzw, 1);
    return p_111 * weight.x + p_max * weight.y + p_min * weight.z + p_000 * weight.w;
}

void PS_CubeLUT3D_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_TARGET0)
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord.xy).xyz;
    float3 lutcolor;
    switch(iSample_Mode)
    {
        case 1:
        {
            lutcolor = Cube3D_Triliniar(sampCube3D, color.xyz, CUBE_3D_SIZE);
            break;
        }
        case 2:
        {
            lutcolor = Cube3D_Tetrahedral(sampCube3D, color.xyz, CUBE_3D_SIZE);
            break;
        }
        default:
        {
            color = (color - 0.5) *((CUBE_3D_SIZE - 1.0) / CUBE_3D_SIZE) + 0.5;
            lutcolor = tex3D(sampCube3D, color.xyz).xyz;
            break;
        }
    }

    lutcolor = lerp(color.xyz, lutcolor, fLUT_Intensity);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) *
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
}

technique CubeLUT3D<
    ui_label = "立方LUT-3D[CubeLUT3D]";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CubeLUT3D_Apply;
    }
}