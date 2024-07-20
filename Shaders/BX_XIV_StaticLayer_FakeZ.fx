// Author: BarricadeMKXX
// 2024-07-20
// License: MIT

#include "BX_XIV_StaticLayer.fxh"

#ifdef SLayer_Quantity
    #undef SLayer_Quantity
#endif

uniform bool bShowZ<
    ui_label = "Show Fake Z Buffer";
> = false;

void InitialZ(in float4 pos : SV_POSITION, in float2 texcoords : TEXCOORD, out float4 col : SV_TARGET0, out float z : SV_TARGET1)
{
    //return GetDepth(texcoords);
    col.rgb = tex2D(ReShade::BackBuffer, texcoords).rgb;
    col.a = 1;
    z = tex2Dlod(ReShade::DepthBuffer, float4(texcoords, 0, 0)).x;
}

float4 PrintZ(in float4 pos : SV_POSITION, in float2 texcoords : TEXCOORD) : SV_TARGET
{
    float4 color;
    if(bShowZ){
#if RESHADE_DEPTH_INPUT_IS_REVERSED != 0
        color.xyz = FFXIV::linearize_depth(1.0 - tex2D(BXCommon::sampBXFakeZ, texcoords).x).xxx;
#else
        color.xyz = LinearizeDepth(tex2D(BXCommon::sampBXFakeZ, texcoords).x).xxx;
#endif
        color.w = 1;
    }
    else{
        color = tex2D(BXCommon::sampBXBuffer, texcoords);
    }
    return color;
}

technique BX_XIV_StaticLayer_Begin
{
    pass{
        VertexShader = PostProcessVS;
        PixelShader = InitialZ;
        RenderTarget0 = BXCommon::texBXBuffer;
        RenderTarget1 = BXCommon::texBXFakeZ;
    }
}

technique BX_XIV_StaticLayer_End
{
    pass{
        VertexShader = PostProcessVS;
        PixelShader = PrintZ;
    }
}