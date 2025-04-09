#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <cuda_runtime.h>
#include "image_utils.h"

__global__ void sharpenKernel(unsigned char* input, unsigned char* output, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    int idx = y * width + x;
    if (x > 0 && y > 0 && x < width-1 && y < height-1) {
        int val =
            -input[(y-1)*width + (x-1)] - input[(y-1)*width + x] - input[(y-1)*width + (x+1)] +
            -input[y*width + (x-1)] + 9*input[y*width + x] - input[y*width + (x+1)] +
            -input[(y+1)*width + (x-1)] - input[(y+1)*width + x] - input[(y+1)*width + (x+1)];

        output[idx] = min(max(val, 0), 255);
    } else if (x < width && y < height) {
        output[idx] = input[idx];
    }
}

void processImage(const cv::Mat& img, cv::Mat& out, cudaStream_t stream) {
    int imgSize = img.rows * img.cols;
    unsigned char *d_in, *d_out;

    cudaMallocAsync(&d_in, imgSize, stream);
    cudaMallocAsync(&d_out, imgSize, stream);

    cudaMemcpyAsync(d_in, img.data, imgSize, cudaMemcpyHostToDevice, stream);

    dim3 threads(16, 16);
    dim3 blocks((img.cols + 15) / 16, (img.rows + 15) / 16);
    sharpenKernel<<<blocks, threads, 0, stream>>>(d_in, d_out, img.cols, img.rows);

    cudaMemcpyAsync(out.data, d_out, imgSize, cudaMemcpyDeviceToHost, stream);

    cudaFreeAsync(d_in, stream);
    cudaFreeAsync(d_out, stream);
}

int main() {
    std::string inputDir = "images/";
    std::string outputDir = "output/";

    auto files = getTiffFiles(inputDir);
    const int streamCount = 4;
    cudaStream_t streams[streamCount];

    for (int i = 0; i < streamCount; ++i)
        cudaStreamCreate(&streams[i]);

    for (size_t i = 0; i < files.size(); ++i) {
        cv::Mat img = readImageCleaned(files[i]);
        if (img.empty()) continue;

        cv::Mat result = img.clone();
        int streamIdx = i % streamCount;

        processImage(img, result, streams[streamIdx]);

        std::string filename = files[i].substr(files[i].find_last_of("/\\") + 1);
        std::string outPath = outputDir + filename;
        saveImage(outPath, result);
    }

    cudaDeviceSynchronize();
    for (int i = 0; i < streamCount; ++i)
        cudaStreamDestroy(streams[i]);

    std::cout << "All images processed.\n";
    return 0;
}