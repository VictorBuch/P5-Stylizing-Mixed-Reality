// Copyright 2020 Varjo Technologies Oy. All rights reserved.

// Compute shader thread block size
#define BLOCK_SIZE (8)

// Debug texture output modes
#define DEBUG_TEXTURE_OUT_NONE (0)
#define DEBUG_TEXTURE_OUT_RGB (1)
#define DEBUG_TEXTURE_OUT_RG_A (2)

// TODO: We could get this mode in constant buffer to be able to switch runtime
#define DEBUG_TEXTURE_OUT (DEBUG_TEXTURE_OUT_NONE)


Texture2D<float4> inputTex : register(t0);  // NOTICE! This is sRGBA data bound as RGBA so fetched values are in screen gamma.


RWTexture2D<float4> outputTex : register(u0);
RWTexture2D<float4> bufferHTex : register(u1);
RWTexture2D<float4> bufferHVTex : register(u2);


// Texture samplers
SamplerState SamplerLinearClamp : register(s0);
SamplerState SamplerLinearWrap : register(s1);


cbuffer ConstantBuffer : register(b0)
{
    int2 sourceSize;   // Source texture dimensions
    float sourceTime;  // Source texture timestamp
    int viewIndex;     // View to be rendered: 0=LC, 1=RC, 2=LF, 3=RF
    int4 destRect;     // Destination rectangle: x, y, w, h
}

cbuffer ConstantBuffer : register(b1)
{     

    int clusterSize;
    float outlineIntensity;
    int watercolorRadius;
    float sketchIntensity;

    float pointilismStep;
    float pointilismThreshold;
    float2 _padding0; 

}

Texture2D<float4> noiseTexture : register(t1);


float getEdgeValue(in float2 uv, in float outlineIntensity) {

    float3x3 gx = float3x3(-1, 0, 1, -2, 0, 2, -1, 0, 1);
    float3x3 gy = float3x3(-1, -2, -1, 0, 0, 0, 1, 2, 1);

    float pixelSumX = 0.0;
    float pixelSumY = 0.0;

    for (int y = -1; y < 2; y++) {
        for (int x = -1; x < 2; x++) {
        
            float4 pixel = inputTex.SampleLevel(SamplerLinearClamp, uv + float2((float) y / sourceSize[0], (float) x / sourceSize[1]), 0.0, 0.0);

            float grayscaleValue = (pixel.r + pixel.g + pixel.b) / 3;
        
            pixelSumX += grayscaleValue * gx[y + 1][x + 1];
            pixelSumY += grayscaleValue * gy[y + 1][x + 1];
        }
    }

    float value = 10.0f - 9.9 * outlineIntensity;

    float outColor = abs(pixelSumX / value) + abs(pixelSumY / value);
    return outColor;
}

float4 applyCartoon(in float2 uv, in int clusterSize, in float outlineIntensity) {

    float4 outColor = inputTex.SampleLevel(SamplerLinearClamp, uv, 0.0, 0.0);

    if (outlineIntensity > 0.0f && getEdgeValue(uv, outlineIntensity) > 0.05) {
        outColor.rgb = float3(0.0, 0.0, 0.0);
    } else if (clusterSize > 0 ) {
        outColor.rgb = round(outColor * clusterSize) / clusterSize;
    }

    return outColor;
}

float4 applyWatercolor(in float2 uv, in int radius) {

    int n = (radius + 1) * (radius + 1);

    float4x3 mat;
    float4x3 matSquared;


    for (int i = 0; i < 4; i++) {
        mat[i] = float3(0.0f, 0.0f, 0.0f);
        matSquared[i] = float3(0.0f, 0.0f, 0.0f);
    }

    for (int y = -radius; y <= 0; y++)  {
        for (int x = -radius; x <= 0; x++)  {
            float3 pixel = inputTex.SampleLevel(SamplerLinearClamp, uv + float2((float) y / sourceSize[0], (float) x / sourceSize[1]), 0.0, 0.0).rgb;
            mat[0] += pixel;
            matSquared[0] += pixel * pixel;
        }
    }

    for (int y = -radius; y <= 0; y++)  {
        for (int x = 0; x <= radius; x++)  {
            float3 pixel = inputTex.SampleLevel(SamplerLinearClamp, uv + float2((float) y / sourceSize[0], (float) x / sourceSize[1]), 0.0, 0.0).rgb;
            mat[1] += pixel;
            matSquared[1] += pixel * pixel;
        }
    }

    for (int y = 0; y <= radius; y++)  {
        for (int x = 0; x <= radius; x++)  {
            float3 pixel = inputTex.SampleLevel(SamplerLinearClamp, uv + float2((float) y / sourceSize[0], (float) x / sourceSize[1]), 0.0, 0.0).rgb;
            mat[2] += pixel;
            matSquared[2] += pixel * pixel;
        }
    }

    for (int y = 0; y <= radius; y++)  {
        for (int x = -radius; x <= 0; x++)  {
            float3 pixel = inputTex.SampleLevel(SamplerLinearClamp, uv + float2((float) y / sourceSize[0], (float) x / sourceSize[1]), 0.0, 0.0).rgb;
            mat[3] += pixel;
            matSquared[3] += pixel * pixel;
        }
    }


    float4 outColor = float4(0.0, 0.0, 0.0, 0.0);

    float min_sigma2 = 100.0f;

    for (int i = 0; i < 4; i++) {
        mat[i] /= n;
        matSquared[i] = abs(matSquared[i] / n - mat[i] * mat[i]);

        float sigma2 = matSquared[i].r + matSquared[i].g + matSquared[i].b;
        if (sigma2 < min_sigma2) {
            min_sigma2 = sigma2;
            outColor.rgb = mat[i];
        }
    }


    return outColor;
}


float4 applySketch(in float2 uv, in float sketchIntensity) {

    float3 W = float3(0.2125, 0.7154, 0.0721);
    float2 stp0 = float2(1.0 / sourceSize[0], 0.0);
    float2 st0p = float2(0.0, 1.0 / sourceSize[1]);
    float2 stpp = float2(1.0 / sourceSize[0], 1.0 / sourceSize[1]);
    float2 stpm = float2(1.0 / sourceSize[0], -1.0 / sourceSize[1]);

    float im1m1 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv - stpp, 0.0, 0.0).rgb, W);
    float ip1p1 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv + stpp, 0.0, 0.0).rgb, W);
    float im1p1 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv - stpm, 0.0, 0.0).rgb, W);
    float ip1m1 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv + stpm, 0.0, 0.0).rgb, W);
    float im10 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv - stp0, 0.0, 0.0).rgb, W);
    float ip10 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv + stp0, 0.0, 0.0).rgb, W);
    float i0m1 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv - st0p, 0.0, 0.0).rgb, W);
    float i0p1 = dot(inputTex.SampleLevel(SamplerLinearClamp, uv + st0p, 0.0, 0.0).rgb, W);

    float  h = -im1p1 - 2.0 * i0p1 - ip1p1 + im1m1 + 2.0 * i0m1 + ip1m1;
    float v = -im1m1 - 2.0 * im10 - im1p1 + ip1m1 + 2.0 * ip10 + ip1p1;

    float magnitude = 1.0 - length(float2(h, v));

    

    float4 outColor = float4(magnitude * sketchIntensity, magnitude * sketchIntensity, magnitude * sketchIntensity, 1.0);

    return outColor;
}

float4 applyPointilism(in float2 uv, in float pointilismStep, in float pointilismThreshold) {

    
    float4 outColor = float4(0.988235, 0.94902, 0.870588, 1.0);

    float2 near_uv = float2(round(uv.x * pointilismStep), round(uv.y * pointilismStep));
    float4 color = inputTex.SampleLevel(SamplerLinearClamp, near_uv / pointilismStep, 0.0, 0.0);

    float color_max = max(max(color.r, color.b), color.g);
    float color_min = min(min(color.r, color.b), color.g);

    float threshold = max((color_min + color_max) / 2.0, pointilismThreshold);

    if (distance(uv * pointilismStep, near_uv) < threshold) {
        outColor.rgb = color.rgb;
    }

    return outColor;
}


[numthreads(BLOCK_SIZE, BLOCK_SIZE, 1)] 
void main(uint3 dispatchThreadID : SV_DispatchThreadID) {

    const int2 thisThread = dispatchThreadID.xy + int2(destRect.xy);
    const float2 uv = float2(thisThread) / sourceSize;

    float4 color;

    if (clusterSize > 0) {
        color = applyCartoon(uv, clusterSize, outlineIntensity);
    }

    if (watercolorRadius > 0) {
        color = applyWatercolor(uv, watercolorRadius);
    }

    if (sketchIntensity > 0.0) {
        color = applySketch(uv, sketchIntensity);
    }

    if (pointilismStep > 0.0) {
        color = applyPointilism(uv, pointilismStep, pointilismThreshold);
    }


    outputTex[thisThread.xy] = color;

}
