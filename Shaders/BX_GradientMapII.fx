// Author: BarricadeMKXX, Sumi
// Version: v1.0.0
// License: MIT

#include "ReShade.fxh"
#include "BX_Colors.fxh"
#include "Blending.fxh"
#include "BX_Multilingual.fxh"

#define LUT_SIZE 1024

namespace BX_GradientMap {

    // uniform int ToneMapping <
    //     ui_category = "General";
    //     ui_label = "Input As";
    //     ui_type = "combo";
    //     ui_items = " Linear\0 SRGB\0";
    // > = 1;
    uniform bool RSOverlay < source = "overlay_open"; >;

    uniform int DrawOverlay <
        CATEGORY("Overlay", "覆盖层")
        LABEL("Mode", "模式")
        ui_type = "combo";
        ITEMS("None\0 Always\0 Overlay\0", "无\0 总是\0 面板可见\0")
    > = 2;

    uniform int OverlaySize <
        CATEGORY("Overlay", "覆盖层")
        ui_category_closed = true;
        LABEL("Size", "尺寸")
        ui_type = "slider";
        ui_min = 256; ui_max = 1536;
    > = 512;

    uniform float2 OverlayPos <
        CATEGORY("Overlay", "覆盖层")
        ui_category_closed = true;
        LABEL("Position", "位置")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(0.5f, 0.5f);

    uniform int LumaFrom <
        CATEGORY("General", "通用")
        LABEL("Luma Mode", "亮度模式")
        ui_type = "combo";
        ui_items = " sRGB Luminance\0 HSL.Lightness \0 HSI.Intensity (Avg)\0 OKLab.Lightness\0";
        ITEMS(" sRGB Luminance\0 HSL.Lightness \0 HSI.Intensity (Avg)\0 OKLab.Lightness\0", \
            " sRGB 亮度\0 HSL 亮度 \0 HSI 强度 (均值)\0 OKLab 亮度\0")
    > = 3;

    uniform int BalanceMode <
        CATEGORY("General", "通用")
        LABEL("Interpolate Mode", "插值模式")
        ui_type = "combo";
        ITEMS(" Linear\0 Smoothstep\0", " 线性\0 平滑\0")
    > = 1;

    uniform int InterpolateSpace <
        CATEGORY("General", "通用")
        LABEL("Interpolate Space", "插值空间")
        ui_type = "combo";
        ITEMS(" sRGB\0 Linear RGB\0 HSV\0 OKLab\0 OKLch\0", " sRGB\0 线性 RGB\0 HSV\0 OKLab\0 OKLch\0")
    > = 3;

    uniform bool ReverseGradient <
        CATEGORY("General", "通用")
        LABEL("Reverse Gradient", "反转渐变")
    > = false;

#if (LANGUAGE == LANG_zh_cn)
    BLENDING_COMBO(BlendingMode, "模式", "", "混合", false, 0, 0)
#else
    BLENDING_COMBO(BlendingMode, "Mode", "", "Blending", false, 0, 0)
#endif

    uniform bool ReverseBlending <
        CATEGORY("Blending", "混合")
        LABEL("Reverse Blending", "交换混合次序")
    > = false;

    uniform float BlendingStrength <
        CATEGORY("Blending", "混合")
        LABEL("Strength", "强度")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = 1.0f;

    uniform int SatEpsilon <
        CATEGORY("Advanced", "高级")
        ui_category_closed = true;
        LABEL("Epsilon Index", "精度指数")
        TOOLTIP("Adjust if there's other hues during Color -> Gray", "如果在颜色->灰度转换中出现其他色调，请调整此值")
        ui_min = 4; ui_max = 12;
        ui_type = "slider";
    > = 8;

    // uniform bool AnchorEnable_0 <
    //     ui_category = "Anchors";
    //     ui_label = "#0  Active";
    //     nosave = 1; noedit = 1; noreset = 1;
    // > = true;
    uniform float4 AnchorCol_0 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_0 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(0.0f, 0.5f);

    // uniform bool AnchorEnable_1 <
    //     ui_category = "Anchors";
    //     ui_label = "#1  Active";
    // > = false;
    uniform float4 AnchorCol_1 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_1 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(-1.0f, 0.5f);

    // uniform bool AnchorEnable_2 <
    //     ui_category = "Anchors";
    //     ui_label = "#2  Active";
    // > = false;
    uniform float4 AnchorCol_2 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_2 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(-1.0f, 0.5f);

    // uniform bool AnchorEnable_3 <
    //     ui_category = "Anchors";
    //     ui_label = "#3  Active";
    // > = false;
    uniform float4 AnchorCol_3 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_3 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(-1.0f, 0.5f);

    // uniform bool AnchorEnable_4 <
    //     ui_category = "Anchors";
    //     ui_label = "#4  Active";
    // > = false;
    uniform float4 AnchorCol_4 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_4 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(-1.0f, 0.5f);

    // uniform bool AnchorEnable_5 <
    //     ui_category = "Anchors";
    //     ui_label = "#5  Active";
    // > = false;
    uniform float4 AnchorCol_5 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_5 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(-1.0f, 0.5f);

    // uniform bool AnchorEnable_6 <
    //     ui_category = "Anchors";
    //     ui_label = "#6  Active";
    // > = false;
    uniform float4 AnchorCol_6 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(0.0f, 0.0f, 0.0f, 1.0f);
    uniform float2 AnchorPos_6 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(-1.0f, 0.5f);

    // uniform bool AnchorEnable_7 <
    //     ui_category = "Anchors";
    //     ui_label = "#7  Active";
    //     nosave = 1; noedit = 1; noreset = 1;
    // > = true;
    uniform float4 AnchorCol_7 <
        ui_spacing = 1;
        CATEGORY("Anchors", "控制点")
        LABEL("Color", "颜色")
        ui_type = "color";
    > = float4(1.0f, 1.0f, 1.0f, 1.0f);
    uniform float2 AnchorPos_7 <
        CATEGORY("Anchors", "控制点")
        LABEL("Position | Balance", "位置 | 平衡")
        ui_type = "slider";
        ui_min = 0.0f; ui_max = 1.0f;
    > = float2(1.0f, 0.5f);

    texture texAnchorData {
        Width = 8;
        Height = 2; // 0: colors 1: pos and balance
        Format = RGBA32F;
    };
    sampler sampAnchorData { Texture = texAnchorData; AddressU = Clamp; AddressV = Clamp; };
    storage wAnchorData { Texture = texAnchorData; };
    
    texture texLUTData {
		Width = LUT_SIZE;
		Height = 1;
		Format = RGBA32F;
	};
    sampler sampLUTData { Texture = texLUTData; AddressU = Clamp; AddressV = Clamp; };
    storage2D wLUTData { Texture = texLUTData; };


    struct AnchorData {
        float4 colors[8];
        float2 positions[8];
        bool enabled[8];
    };
    groupshared AnchorData Anchors;

    struct AnchorSortItem {
        float pos;
        int index;
    };
    groupshared AnchorSortItem AnchorIndex[8];
    groupshared int AnchorCount;

    void sort2(inout AnchorSortItem al, inout AnchorSortItem ar) {
        // Use the original index to make equal-position ordering deterministic.
        if (al.pos > ar.pos || (al.pos == ar.pos && al.index > ar.index)) {
            AnchorSortItem tmp = al;
            al = ar;
            ar = tmp;
        }
    }

    void GetAnchorsCS(uint3 id : SV_DispatchThreadID) {
        // anchor loading
        uint tid = id.x;
        if (tid == 0) {
            Anchors.colors = {AnchorCol_0, AnchorCol_1, AnchorCol_2, AnchorCol_3, AnchorCol_4, AnchorCol_5, AnchorCol_6, AnchorCol_7};
            Anchors.positions = {AnchorPos_0, AnchorPos_1, AnchorPos_2, AnchorPos_3, AnchorPos_4, AnchorPos_5, AnchorPos_6, AnchorPos_7};
            // Anchors.enabled = {true, AnchorEnable_1, AnchorEnable_2, AnchorEnable_3, AnchorEnable_4, AnchorEnable_5, AnchorEnable_6, true};

            // AnchorCount = 0;
            // for(int i = 0; i < 8; i++)
            //     AnchorCount += Anchors.positions.x < 0.0f ? 1 : 0;
        }
        barrier();

        AnchorIndex[tid].pos = Anchors.positions[tid].x >= 0.0f ? Anchors.positions[tid].x : (2.0f + tid * 0.1f);
        AnchorIndex[tid].index = tid;
        barrier();
        // 8-element sorting network
        if (tid == 0) {
            sort2(AnchorIndex[0], AnchorIndex[2]);
            sort2(AnchorIndex[1], AnchorIndex[3]);
            sort2(AnchorIndex[4], AnchorIndex[6]);
            sort2(AnchorIndex[5], AnchorIndex[7]);


            sort2(AnchorIndex[0], AnchorIndex[4]);
            sort2(AnchorIndex[1], AnchorIndex[5]);
            sort2(AnchorIndex[2], AnchorIndex[6]);
            sort2(AnchorIndex[3], AnchorIndex[7]);
            
            sort2(AnchorIndex[0], AnchorIndex[1]);
            sort2(AnchorIndex[2], AnchorIndex[3]);
            sort2(AnchorIndex[4], AnchorIndex[5]);
            sort2(AnchorIndex[6], AnchorIndex[7]);

            sort2(AnchorIndex[2], AnchorIndex[4]);
            sort2(AnchorIndex[3], AnchorIndex[5]);
            
            sort2(AnchorIndex[1], AnchorIndex[4]);
            sort2(AnchorIndex[3], AnchorIndex[6]);

            sort2(AnchorIndex[1], AnchorIndex[2]);
            sort2(AnchorIndex[3], AnchorIndex[4]);
            sort2(AnchorIndex[5], AnchorIndex[6]);
        }
        barrier();

        tex2Dstore(wAnchorData, int2(tid, 0), Anchors.colors[AnchorIndex[tid].index]); // color
        tex2Dstore(wAnchorData, int2(tid, 1), float4(
            AnchorIndex[tid].pos, // position
            Anchors.positions[AnchorIndex[tid].index].y, // balance
            0.0f, 1.0f
        ));
    }

    float4 GradientLUTPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
        float edgeL = 0.0f;
        float edgeR = 0.0f;
        float balance = tex2Dfetch(sampAnchorData, int2(0, 1)).y;// balance of R

        float4 colorL = float4(0.0f, 0.0f, 0.0f, 1.0f);
        float4 colorR = tex2Dfetch(sampAnchorData, int2(0, 0));
        float interp = 1.0f;

        for (int j = 0; j < 8; j++) {
            edgeR = tex2Dfetch(sampAnchorData, int2(j, 1)).x;
            colorR = tex2Dfetch(sampAnchorData, int2(j, 0));
            // very right
            if (edgeR >= 2.0f) {
                interp = 0.0f;
                balance = 0.5f;
                break;
            }
            if (texcoord.x >= edgeL && texcoord.x <= edgeR) {
                // colorR = tex2Dfetch(sampAnchorData, int2(j, 0));
                interp = (texcoord.x - edgeL) / (edgeR - edgeL);
                // balance from edgeL, so do not update here.
                break;
            }
            edgeL = edgeR;
            colorL = colorR;
            balance = tex2Dfetch(sampAnchorData, int2(j, 1)).y; // balance
        }

        switch (BalanceMode) {
            case 1: // smoothstep aware of balance
                interp = (1 - balance) * interp / (balance + (1 - 2 * balance) * interp); 
                break;
            default: // Linear
                interp = interp < balance ? lerp(0, 0.5, interp / balance) : lerp(0.5, 1, (interp - balance) / (1 - balance));
                break;
        }

        float4 outcolor;

        float epsilon = 1.0f / (1 << SatEpsilon);

        switch (InterpolateSpace) {
            case 1: // Linear RGB
                float3 linL = BXCol::SRGBToLinear(colorL.rgb);
                float3 linR = BXCol::SRGBToLinear(colorR.rgb);
                outcolor.rgb = BXCol::LinearToSRGB(lerp(linL, linR, interp));
                outcolor.a = lerp(colorL.a, colorR.a, interp);
                break;
            case 2: // HSV
                float3 hsvL = BXCol::RGBToHSV(colorL.rgb);
                float3 hsvR = BXCol::RGBToHSV(colorR.rgb);

                // hue hack
                hsvL.x = hsvL.y < epsilon ? hsvR.x : hsvL.x;
                hsvR.x = hsvR.y < epsilon ? hsvL.x : hsvR.x;
                if (hsvL.x - hsvR.x >= 0.5f)
                    hsvR.x += 1.0f;
                else if (hsvR.x - hsvL.x >= 0.5f)
                    hsvL.x += 1.0f;
                outcolor.xyz = lerp(hsvL, hsvR, interp);
                outcolor.x = outcolor.x >= 1.0f ? outcolor.x - 1.0f : outcolor.x;
                //
                outcolor.rgb = BXCol::HSVToRGB(outcolor.xyz);
                outcolor.a = lerp(colorL.a, colorR.a, interp);
                break;
            case 3: // OKLab
                float3 oklabL = BXCol::LinearRGBToOKLAB(BXCol::SRGBToLinear(colorL.rgb));
                float3 oklabR = BXCol::LinearRGBToOKLAB(BXCol::SRGBToLinear(colorR.rgb));
                outcolor.rgb = BXCol::LinearToSRGB(BXCol::OKLABToLinearRGB(lerp(oklabL, oklabR, interp)));
                outcolor.a = lerp(colorL.a, colorR.a, interp);
                break;
            case 4: // OKLch
                float3 oklchL = BXCol::LinearRGBToOKLCH(BXCol::SRGBToLinear(colorL.rgb));
                float3 oklchR = BXCol::LinearRGBToOKLCH(BXCol::SRGBToLinear(colorR.rgb));

                // hue hack
                oklchL.z = oklchL.y < epsilon ? oklchR.z : oklchL.z;
                oklchR.z = oklchR.y < epsilon ? oklchL.z : oklchR.z;
                if (oklchL.z - oklchR.z >= 0.5f)
                    oklchR.z += 1.0f;
                else if (oklchR.z - oklchL.z >= 0.5f)
                    oklchL.z += 1.0f;
                outcolor.xyz = lerp(oklchL, oklchR, interp);
                outcolor.z = outcolor.z >= 1.0f ? outcolor.z - 1.0f : outcolor.z;
                // 
                outcolor.rgb = BXCol::LinearToSRGB(BXCol::OKLCHToLinearRGB(outcolor.xyz));
                outcolor.a = lerp(colorL.a, colorR.a, interp);
                break;
            default:
            case 0: // Raw RGB
                outcolor = lerp(colorL, colorR, interp);
                break;
        }

        return outcolor;
    }

    float4 ApplyGradientPS(float4 pos : SV_Position, float2 texcoord :TEXCOORD) : SV_Target {
        float4 col = tex2D(ReShade::BackBuffer, texcoord);
        float4 src = col;

        float lightness_in;
        switch(LumaFrom) {
            case 0: // sRGB
                lightness_in = dot(col.rgb, float3(0.2126, 0.7152, 0.0722));
                break;
            case 1: // HSL.L
                lightness_in = max(col.r, max(col.g, col.b)) + min(col.r, min(col.g, col.b));
                lightness_in *= 0.5f;
                break;
            case 2: // HSI.I
                lightness_in = (col.r + col.g + col.b) / 3.0f;
                break;
            case 3: // OKLab
                lightness_in = BXCol::LinearRGBToOKLAB(BXCol::SRGBToLinear(col.rgb)).x;
                break;
        }
        lightness_in = saturate(lightness_in);
        lightness_in = ReverseGradient ? 1.0f - lightness_in : lightness_in;

        col.rgba = tex2D(sampLUTData, float2(lightness_in, 0.5)).rgba;

        if(ReverseBlending) {
            col.rgb = ComHeaders::Blending::Blend(BlendingMode, col.rgb, src.rgb, BlendingStrength);
            col.rgb = lerp(src.rgb, col.rgb, col.a);
        }
        else
            col.rgb = ComHeaders::Blending::Blend(BlendingMode, src.rgb, col.rgb, col.a * BlendingStrength);
        col.a = src.a;
        return col;
    }

    float4 DrawOverlayPS(float4 pos : SV_Position, float2 texcoord :TEXCOORD) : SV_Target {
        // float4 color = tex2D(ReShade::BackBuffer, texcoord);
        float4 color = float4(0, 0, 0, 0);

        if (DrawOverlay == 0 || DrawOverlay == 2 && !RSOverlay){
            discard;
        }
            
        const float BorderSize = OverlaySize / 64.0f;
        const float LineSize = OverlaySize / 128.0f;
        const float OverlayHeight = OverlaySize / 16.0f;

        float2 coord = texcoord * ReShade::ScreenSize;
        float2 center = OverlayPos * ReShade::ScreenSize;
        if (abs(coord.x - center.x) * 2.0f <= OverlaySize + BorderSize && abs(coord.y - center.y) * 2.0f <= OverlayHeight + BorderSize) {
            color = float4(0.5, 0.5, 0.5, 1.0);
        }
        if (abs(coord.x - center.x) * 2.0f <= OverlaySize && abs(coord.y - center.y) * 2.0f <= OverlayHeight) {
            float pos = 0.5 - (OverlayPos.x - texcoord.x) * ReShade::ScreenSize.x * rcp(OverlaySize);


            int2 coord_i = floor(coord / BorderSize);

            color = lerp(float4(0.3f, 0.3f, 0.3f, 1.0f), float4(0.7f, 0.7f, 0.7f, 1.0f), coord_i.x % 2 == coord_i.y % 2 ? 1 : 0);
            float4 newcolor = tex2D(sampLUTData, float2(pos, 0.5f));
            color.xyz = lerp(color.rgb, newcolor.rgb, newcolor.a);
        }

        for (int j = 0; j < 8; j++) {
            float2 anchor_data_pos = tex2Dfetch(sampAnchorData, int2(j, 1)).xy;

            if (anchor_data_pos.x >= 2.0f)
                break;
            
            float2 anchor_overlay_pos = float2(anchor_data_pos.x - 0.5, 0) * OverlaySize + OverlayPos * ReShade::ScreenSize;
            float anchor_dist = distance(coord, anchor_overlay_pos);
            color = lerp(color, float4(1.0, 1.0, 1.0, 1.0), 1.0 - smoothstep(-1.0f, 1.0f, abs(anchor_dist - BorderSize) - LineSize * 0.5f));
            color = lerp(color, float4(0.0, 0.0, 0.0, 1.0), 1.0 - smoothstep(-1.0f, 1.0f, abs(anchor_dist - BorderSize - LineSize * 0.5f) - LineSize * 0.125f));

            if (j < 7){
                float next_anchor_pos = tex2Dfetch(sampAnchorData, int2(j+1, 1)).x;
                if (next_anchor_pos >= 2.0f)
                    break;

                float balance_pos = lerp(anchor_data_pos.x, next_anchor_pos, anchor_data_pos.y);
                float2 balance_overlay_pos = float2(balance_pos - 0.5, 0) * OverlaySize + OverlayPos * ReShade::ScreenSize;
                float balance_dist = dot(abs(coord - balance_overlay_pos), float2(1.0f, 1.0f));
                color = lerp(color, float4(1.0, 1.0, 1.0, 1.0), 1.0 - smoothstep(-1.0f, 1.0f, abs(balance_dist - BorderSize * 0.6f) - LineSize * 0.3f));
                color = lerp(color, float4(0.0, 0.0, 0.0, 1.0), 1.0 - smoothstep(-1.0f, 1.0f, abs(balance_dist - BorderSize * 0.6f - LineSize * 0.5f) - LineSize * 0.125f));
            }

        }
        return color;
    };

    technique BX_GradientMapII <
        ui_label = "BX::Gradient Map II";
        ui_label_zh = "BX::渐变映射II";
    >{
        pass buildAnchors {
            ComputeShader = GetAnchorsCS<8, 1>;
            DispatchSizeX = 1;
            DispatchSizeY = 1;
        }
        pass buildLUT {
            VertexShader = PostProcessVS;
            PixelShader = GradientLUTPS;
            RenderTarget = texLUTData;
        }
        pass applyGradient {
            VertexShader = PostProcessVS;
            PixelShader = ApplyGradientPS;
        }
        pass drawOverlay {
            VertexShader = PostProcessVS;
            PixelShader = DrawOverlayPS;

            BlendEnable = TRUE;
            BlendOp = ADD;
            BlendOpAlpha = ADD;
            SrcBlend = SRCALPHA;
            SrcBlendAlpha = ONE;
            DestBlend = INVSRCALPHA;
            DestBlendAlpha = ZERO;
        }
    }
}
