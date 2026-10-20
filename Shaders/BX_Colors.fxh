#undef fmod
#define fmod(x, y)(x - y * floor(x / y))

// OKLAB matrices
// https://bottosson.github.io/posts/oklab/

namespace BXCol {

    static const float3x3 lrgb2cone = float3x3(
        0.4122214708f, 0.2119034982f, 0.0883024619f,
        0.5363325363f, 0.6806995451f, 0.2817188376f,
        0.0514575653f, 0.1073969566f, 0.6299787005f
    );

    static const float3x3 cone2lab = float3x3(
        +0.2104542553f, +1.9779984951f, +0.0259040371f,
        +0.7936177850f, -2.4285922050f, +0.7827717662f,
        -0.0040720468f, +0.4505937099f, -0.8086757660f
    );

    static const float3x3 cone2lrgb = float3x3(
        +4.0767416621f, -1.2684380046f, -0.0041960863f,
        -3.3077115913f, +2.6097574011f, -0.7034186147f,
        +0.2309699292f, -0.3413193965f, +1.7076147010f
    );

    static const float3x3 lab2cone = float3x3(
        1.0f, 1.0f, 1.0f,
        +0.3963377774f, -0.1055613458f, -0.0894841775f,
        +0.2158037573f, -0.0638541728f, -1.2914855480f);

    float3 LinearRGBToOKLAB(float3 col) {    
        col = mul(col, lrgb2cone);
        col = pow(col, 1.0 / 3.0);
        col = mul(col, cone2lab);
        return col;
    }

    float3 LinearRGBToOKLCH(float3 col) {
        col = LinearRGBToOKLAB(col);

        float3 lch = 0.0f;
        lch.r = col.x;
        lch.g = sqrt(col.g * col.g + col.b * col.b);
        lch.b = fmod((atan2(col.b, col.g)/6.28318531), 1.0f);

        return lch;
    }

    float3 OKLABToLinearRGB(float3 col) {
        col = mul(col, lab2cone);
        col = col * col * col;
        col = mul(col, cone2lrgb);
        return col;
    }

    float3 OKLCHToLinearRGB(float3 col) {
        float3 oklab = 0.0f;
        col.b = col.b * 6.28318531f;
        oklab.r = col.r;
        oklab.g = col.g * cos(col.b);
        oklab.b = col.g * sin(col.b);

        return OKLABToLinearRGB(oklab);
    }

    float3 LinearToSRGB( float3 color )
    {
        float3 x = color * 12.92f;
        float3 y = 1.055f * pow(saturate(color), 1.0f / 2.4f) - 0.055f;

        float3 clr = color;
        clr.r = color.r < 0.0031308f ? x.r : y.r;
        clr.g = color.g < 0.0031308f ? x.g : y.g;
        clr.b = color.b < 0.0031308f ? x.b : y.b;

        return clr;
    }

    float3 SRGBToLinear( float3 color )
    {
        float3 x = color / 12.92f;
        float3 y = pow(max((color + 0.055f) / 1.055f, 0.0f), 2.4f);

        float3 clr = color;
        clr.r = color.r <= 0.04045f ? x.r : y.r;
        clr.g = color.g <= 0.04045f ? x.g : y.g;
        clr.b = color.b <= 0.04045f ? x.b : y.b;

        return clr;
    }

    float3 RGBToHCV(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
        float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

        float chroma = q.x - min(q.w, q.y);
        float hue = abs(q.z + (q.w - q.y) / (6.0 * chroma + 1.0e-10));
        return float3(hue, chroma, q.x);
    }

    float3 HCVToRGB(float3 c)
    {
        const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        return c.z * lerp(K.xxx, saturate(abs(frac(c.xxx + K.xyz) * 6.0 - K.www) - K.xxx), saturate(c.y / max(c.z, 0.000001f)));
    }

    float3 RGBToHSV(float3 c) {
        float3 hcv = RGBToHCV(c);
        return float3(hcv.x, hcv.y / (hcv.z + 1.0e-10), hcv.z);
    }

    float3 HSVToRGB(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
    }

    float3 RGBToHSL(float3 c) {
        // Use the same six-sector hue convention as HSV without changing the legacy HSV path.
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
        float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);
        float minimum = min(q.w, q.y);
        float chroma = q.x - minimum;
        float sum = q.x + minimum;
        // Equivalent to 1-abs(2*L-1), avoiding cancellation near black.
        float range = min(sum, (1.0 - q.x) + (1.0 - minimum));
        float safeChroma = chroma > 0.0 ? chroma : 1.0;
        float hue = chroma > 0.0 ? abs(q.z + (q.w - q.y) / (6.0 * safeChroma)) : 0.0;
        float saturation = saturate(chroma / (range > 0.0 ? range : 1.0));
        return float3(hue, saturation, sum * 0.5);
    }

    float3 HSLToRGB(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        float chroma = 2.0 * min(c.z, 1.0 - c.z) * c.y;
        return saturate((c.z - 0.5 * chroma) + chroma * saturate(p - K.xxx));
    }

}