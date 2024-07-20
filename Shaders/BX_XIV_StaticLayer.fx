// Author: BarricadeMKXX
// 2024-07-20
// License: MIT

include "BX_XIV_StaticLayer.fxh"

#define General_Category0 "| 一般设置\n"
#if RESHADE_DEPTH_INPUT_IS_REVERSED != 0
    #define General_Category1 "| 游戏版本：金曦\n| 深度设置：反转深度/ RESHADE_DEPTH_INPUT_IS_REVERSED = 1\n"
#else
    #define General_Category1 "| 游戏版本：晓月\n| 深度设置：普通深度/ RESHADE_DEPTH_INPUT_IS_REVERSED = 0\n"
#endif
#define General_Category2 "若以上内容与游戏不匹配，请手动修改全局预处理器定义中的 RESHADE_DEPTH_INPUT_IS_REVERSED，晓月为0，金曦为1。"

uniform int bInverse<
    ui_type = "radio";
    ui_label = " ";
    ui_text = General_Category2;
    ui_category = General_Category0 General_Category1;
    nosave = 1; noedit = 1; noreset = 1;
> = RESHADE_DEPTH_INPUT_IS_REVERSED;

uniform float fSkyDepth<
    ui_label = "天空阈值";
    ui_type = "slider";
    ui_min = 0.0f; ui_max = 1.0f; ui_step = 0.0001;
    ui_category = General_Category0 General_Category1;
> = 0.999f;

uniform int mSLayerQuantity <
    ui_label = "静态图层数量";
    ui_type = "combo";
    ui_items = " 1\0 2\0 3\0 4\0 5\0";
    ui_bind = "SLayer_Quantity";
    ui_category = General_Category0 General_Category1;
> = 0;

uniform float fDotSize <
    ui_label = "控制点尺寸";
    ui_type = "slider";
    ui_min = 2.0; ui_max = 20.0; ui_step = 1.0;
    ui_category = General_Category0 General_Category1;
> = 5.0f;

#ifndef SLayer1_Name
    #define SLayer1_Name "StaticLayerTemplate1.png"
#endif
#ifndef SLayer1_SizeX
    #define SLayer1_SizeX 1920.0
#endif
#ifndef SLayer1_SizeY
    #define SLayer1_SizeY 1080.0
#endif
SLayer_SUMMON(1, SLayer1_Name, SLayer1_SizeX, SLayer1_SizeY)

#if SLayer_Quantity >= 1
    #if exists("DirtA.png")
        #ifndef SLayer2_Name
            #define SLayer2_Name "DirtA.png"
        #endif
        #ifndef SLayer2_SizeX
            #define SLayer2_SizeX 1920.0
        #endif
        #ifndef SLayer2_SizeY
            #define SLayer2_SizeY 1080.0
        #endif
    #else
        #ifndef SLayer2_Name
            #define SLayer2_Name "StaticLayerTemplate1.png"
        #endif
        #ifndef SLayer2_SizeX
            #define SLayer2_SizeX 1920.0
        #endif
        #ifndef SLayer2_SizeY
            #define SLayer2_SizeY 1080.0
        #endif
    #endif
    SLayer_SUMMON(2, SLayer2_Name, SLayer2_SizeX, SLayer2_SizeY)
#endif

#if SLayer_Quantity >= 2
    #if exists("Dirt3.png")
        #ifndef SLayer3_Name
            #define SLayer3_Name "Dirt3.png"
        #endif
        #ifndef SLayer3_SizeX
            #define SLayer3_SizeX 1920.0
        #endif
        #ifndef SLayer3_SizeY
            #define SLayer3_SizeY 1080.0
        #endif
    #else
        #ifndef SLayer3_Name
            #define SLayer3_Name "StaticLayerTemplate1.png"
        #endif
        #ifndef SLayer3_SizeX
            #define SLayer3_SizeX 1920.0
        #endif
        #ifndef SLayer3_SizeY
            #define SLayer3_SizeY 1080.0
        #endif
    #endif
    SLayer_SUMMON(3, SLayer3_Name, SLayer3_SizeX, SLayer3_SizeY)
#endif

#if SLayer_Quantity >= 3
    #if exists("Dirt4.png")
        #ifndef SLayer4_Name
            #define SLayer4_Name "Dirt4.png"
        #endif
        #ifndef SLayer4_SizeX
            #define SLayer4_SizeX 1920.0
        #endif
        #ifndef SLayer4_SizeY
            #define SLayer4_SizeY 1080.0
        #endif
    #else
        #ifndef SLayer4_Name
            #define SLayer4_Name "StaticLayerTemplate1.png"
        #endif
        #ifndef SLayer4_SizeX
            #define SLayer4_SizeX 1920.0
        #endif
        #ifndef SLayer4_SizeY
            #define SLayer4_SizeY 1080.0
        #endif
    #endif
    SLayer_SUMMON(4, SLayer4_Name, SLayer4_SizeX, SLayer4_SizeY)
#endif

#if SLayer_Quantity >= 4
    #if exists("DirtA.png")
        #ifndef SLayer5_Name
            #define SLayer5_Name "DirtA.png"
        #endif
        #ifndef SLayer5_SizeX
            #define SLayer5_SizeX 1920.0
        #endif
        #ifndef SLayer5_SizeY
            #define SLayer5_SizeY 1080.0
        #endif
    #else
        #ifndef SLayer5_Name
            #define SLayer5_Name "StaticLayerTemplate1.png"
        #endif
        #ifndef SLayer5_SizeX
            #define SLayer5_SizeX 1920.0
        #endif
        #ifndef SLayer5_SizeY
            #define SLayer5_SizeY 1080.0
        #endif
    #endif
    SLayer_SUMMON(5, SLayer5_Name, SLayer5_SizeX, SLayer5_SizeY)
#endif