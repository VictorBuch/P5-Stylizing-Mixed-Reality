// Copyright 2020 Varjo Technologies Oy. All rights reserved.

// Compute shader thread block size
#define BLOCK_SIZE (8)

// Debug texture output modes
#define DEBUG_TEXTURE_OUT_NONE (0)
#define DEBUG_TEXTURE_OUT_RGB (1)
#define DEBUG_TEXTURE_OUT_RG_A (2)

// TODO: We could get this mode in constant buffer to be able to switch runtime
#define DEBUG_TEXTURE_OUT (DEBUG_TEXTURE_OUT_NONE)
//#define DEBUG_TEXTURE_OUT (DEBUG_TEXTURE_OUT_RG_A)

// -------------------------------------------------------------------------

// Shader input layout V1 built-in bindings

// Input buffers: t0 = Camera image input
Texture2D<float4> inputTex : register(t0);  // NOTICE! This is sRGBA data bound as RGBA so fetched values are in screen gamma.

// Output buffers: u0 = Camera image output
RWTexture2D<float4> outputTex : register(u0);

// Texture samplers
SamplerState SamplerLinearClamp : register(s0);
SamplerState SamplerLinearWrap : register(s1);

// Varjo generic constants
cbuffer ConstantBuffer : register(b0)
{
    int2 sourceSize;   // Source texture dimensions
    float sourceTime;  // Source texture timestamp
    int viewIndex;     // View to be rendered: 0=LC, 1=RC, 2=LF, 3=RF
    int4 destRect;     // Destination rectangle: x, y, w, h
}


// Shader specific constants
cbuffer ConstantBuffer : register(b1)
{        

    
    int clusterSize;
    float outlineIntensity;

    int watercolorRadius;

    float sketchIntensity;

    float pointilismStep;
    float pointilismThreshold;

    int grayscale;
    int puzzle;
    float2 mirror_mat;
    
    float2 _padding0; 

    
  
}


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


float3 applyCartoon(in float2 uv, in int clusterSize, in float outlineIntensity) {

    float3 outColor = inputTex.SampleLevel(SamplerLinearClamp, uv, 0.0, 0.0).rgb;

    if (outlineIntensity > 0.0f && getEdgeValue(uv, outlineIntensity) > 0.05) {
        outColor = float3(0.0f, 0.0f, 0.0f);
    } else if (clusterSize > 0 ) {
        outColor = round(outColor * clusterSize) / clusterSize;
    }

    return outColor;
}

float3 applyWatercolor(in float2 uv, in int radius) {

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


    float3 outColor = float3(0.0f, 0.0f, 0.0f);

    float min_sigma2 = 100.0f;

    for (int i = 0; i < 4; i++) {
        mat[i] /= n;
        matSquared[i] = abs(matSquared[i] / n - mat[i] * mat[i]);

        float sigma2 = matSquared[i].r + matSquared[i].g + matSquared[i].b;
        if (sigma2 < min_sigma2) {
            min_sigma2 = sigma2;
            outColor = mat[i];
        }
    }


    return outColor;
}

float3 applySketch(in float2 uv, in float sketchIntensity) {

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

    

    float3 outColor = float3(magnitude * sketchIntensity, magnitude * sketchIntensity, magnitude * sketchIntensity);

    return outColor;
}

float3 applyPointilism(in float2 uv, in float pointilismStep, in float pointilismThreshold) {

    
    float3 outColor = float3(0.988235, 0.94902, 0.870588);

    float2 near_uv = float2(round(uv.x * pointilismStep), round(uv.y * pointilismStep));
    float3 color = inputTex.SampleLevel(SamplerLinearClamp, near_uv / pointilismStep, 0.0, 0.0).rgb;

    float color_max = max(max(color.r, color.b), color.g);
    float color_min = min(min(color.r, color.b), color.g);
    float delta = color_max - color_min;

    float threshold = max((color_min + color_max) / 2.0, pointilismThreshold);

    if (distance(uv * pointilismStep, near_uv) < threshold) {
        outColor = color;
    }

    return outColor;
}

float3 applyBlur(in float2 uv, in int radius) {

    float filter_size = float((radius * 2) * (radius * 2));
    float3 sum = float3(0.0f, 0.0f, 0.0f);

    for (int x = -radius; x < radius; x++)  {
        for (int y = -radius; y < radius; y++)  {
            float2 uvOffset = float2((float) x / sourceSize[0], (float) y / sourceSize[1]);
            float3 color = inputTex.SampleLevel(SamplerLinearClamp, uv + uvOffset), 0.0, 0.0).rgb;
            sum += color;
        }
    }

    float3 outColor = sum / filter_size;
    return outColor;
}

// Stylization branch




float3 applyPuzzleEffect(in float2 uv) {

    int2 puzzle_level = int2(5, 5);
    int random_puzzle_variation[25] = {17, 21, 15, 22, 9, 0, 10, 23, 6, 4, 19, 12, 11, 2, 14, 5, 13, 24, 1, 7, 20, 8, 16, 18, 3};

    // int2 puzzle_level = int2(2, 2);
    // int random_puzzle_variation[4] = {3, 2, 1, 0};

    int2 position_SS = int2(uv * sourceSize);
    int2 chunk_index_SS = position_SS * puzzle_level / sourceSize;
    int chunk_index = chunk_index_SS.y * puzzle_level.x + chunk_index_SS.x; 
    int new_chunk_index = random_puzzle_variation[chunk_index];
    int2 chunk_pos_index_SS = position_SS % (sourceSize / puzzle_level);
    int2 new_position_SS = int2(new_chunk_index % puzzle_level.x, new_chunk_index / puzzle_level.x) * (sourceSize / puzzle_level) + chunk_pos_index_SS;
    float2 new_uv = (float2) new_position_SS / sourceSize;

    float3 outColor = inputTex.SampleLevel(SamplerLinearClamp, new_uv, 0.0, 0.0).rgb;
    return outColor;
}

float3 applyMirrorEffect(in float2 uv, in float2 mirror_mat) {

    float2 new_uv = abs(mirror_mat - uv);

    float3 outColor = inputTex.SampleLevel(SamplerLinearClamp, new_uv, 0.0, 0.0).rgb;
    return outColor;

}


[numthreads(BLOCK_SIZE, BLOCK_SIZE, 1)] void main(uint3 dispatchThreadID
                                                  : SV_DispatchThreadID) {
    // Calculate thread coordinates
    const int2 thisThread = dispatchThreadID.xy + int2(destRect.xy);
    const float2 uv = float2(thisThread) / sourceSize;

    // Load source sample
    float4 origColor = inputTex.Load(int3(thisThread.xy, 0)).rgba;
    float4 color = origColor;

    if (clusterSize > 0 || outlineIntensity > 0.0f) {
        color.rgb = applyCartoon(uv, clusterSize, outlineIntensity);
    }

    if (watercolorRadius > 0) {
        color.rgb = applyWatercolor(uv, watercolorRadius);
    }

    
    if (sketchIntensity > 0.0f) {
        color.rgb = applySketch(uv, sketchIntensity);
    }

    if (pointilismStep > 0.0f || pointilismThreshold > 0.0f) {
        color.rgb = applyPointilism(uv, pointilismStep, pointilismThreshold);
    }


    if (grayscale == 1) {
        float grayscaleValue = (color.r + color.g + color.b) / 3;
        color.rgb = float3(grayscaleValue, grayscaleValue, grayscaleValue);
    }

    if (puzzle == 1) {
        color.rgb = applyPuzzleEffect(uv);
    }

    if (mirror_mat.x != 0.0f || mirror_mat.y != 0.0f) {
        color.rgb = applyMirrorEffect(uv, mirror_mat);
    }

    

    
    outputTex[thisThread.xy] = float4(color.rgb, origColor.a);
}