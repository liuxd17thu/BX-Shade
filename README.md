# BX-Shade
Some ReShade Shaders made by BarricadeMKXX

## Curve Tool & Cross-Channel Curve Tool
### `BX_ToyCurveTool.fx`:

Adjust color in game with R/G/B/RGB curves.

This shader roughly behaves the same as curve tools in Photoshop / GIMP / Krita, but only supports up to 6(8) anchors in a single curve.

### `BX_XChannelCurve.fx`:

A modified version of curve tool. 
It is possible to use different channels (RGBHSV) as the curve input and output.

For example, you can adjust value(V) based on the strength of red(R), or adjust saturation(S) for different Hue(H).

### Known Issue
The UI is kind of difficult to use ...

This compute shader has been only tested on FFXIV (DX11), so I'm not sure if it will work on other games.
