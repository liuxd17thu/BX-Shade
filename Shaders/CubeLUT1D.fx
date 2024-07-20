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
    ui_category = "1D Cube LUT导入说明";
    ui_text =   "！该着色器专用于加载1D的cube文件，3D LUT请使用CubeLUT3D.fx！\n"
                "导入自定义cube文件：\n"
                "1. 将cube文件置于ReShade的纹理搜索路径下，通常为 \"前面一堆/reshade-shaders/Textures/\"\n"
                "2. 在 SOURCE_CUBELUT1D_FILE 处填入该文件的文件名\n"
                "3. 在 CUBE_3D_SIZE 处填入该cube文件的尺寸，通常是16/17/32/33/64/65之一\n"
                "3? 但如果你不确定：\n"
                "  使用记事本等工具打开cube文件，开头几行中找到LUT_1D_SIZE，其后的数字就是尺寸值\n"
                "  数值错误会导致画面立刻黑屏！\n"
    ;
    ui_category_closed = true;
>;

uniform int iSample_Mode<
    ui_type = "combo";
    ui_label = "采样模式";
    ui_items = "ReShade内置\0线性\0";
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

#ifndef SOURCE_CUBELUT1D_FILE
    #define SOURCE_CUBELUT1D_FILE "Neutral33-1D.cube"
#endif

#ifndef CUBE_1D_SIZE
    #define CUBE_1D_SIZE 33
#endif

texture1D texCube1D < source = SOURCE_CUBELUT1D_FILE; >
{
    Width = CUBE_1D_SIZE;
    Format = RGBA32F;
};

sampler1D sampCube1D
{
    Texture = texCube1D;
    AddressU = CLAMP;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
};

float3 Cube1D_Liniar(sampler1D cube1D, float3 in_color, int cube_size)
{
    in_color = saturate(in_color) * (cube_size - 1);
    int3 indexL = int3(floor(in_color).xyz);
    int3 indexR = int3(ceil(in_color).xyz);
    float3 q = in_color - indexL;

    float3 colorL, colorR;
    for(int i = 0; i < 3; i++)
    {
        float3 tmp = tex1Dfetch(cube1D, indexL[i]).xyz;
        colorL[i] = tmp[i];
        tmp = tex1Dfetch(cube1D, indexR[i]).xyz;
        colorR[i] = tmp[i];
    }
    return float3(
        lerp(colorL.x, colorR.x, q.x),
        lerp(colorL.y, colorR.y, q.y),
        lerp(colorL.z, colorR.z, q.z)
    );
}

void PS_CubeLUT1D_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_TARGET0)
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord.xy).xyz;

    float3 lutcolor;
    
    switch(iSample_Mode)
    {
        case 1:
        {
            lutcolor = Cube1D_Liniar(sampCube1D, color, CUBE_1D_SIZE);
            break;
        }
        default:
        {
            color = (color - 0.5) *((CUBE_1D_SIZE - 1.0) / CUBE_1D_SIZE) + 0.5;
            lutcolor = float3(tex1D(sampCube1D, color.x).x, tex1D(sampCube1D, color.y).y, tex1D(sampCube1D, color.z).z);
            break;
        }
    }

    lutcolor = lerp(color.xyz, lutcolor, fLUT_Intensity);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) *
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
}

technique CubeLUT1D<
    ui_label = "立方LUT-1D[CubeLUT1D]";
    ui_tooltip = "1D的.cube文件你就当它是RGB三根曲线就好，它们之间互相无关。";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CubeLUT1D_Apply;
    }
}