CUDA_PATH ?= /usr/local/cuda
NVCCFLAGS = -arch=sm_61 --std=c++17 -O2
CXXFLAGS = -std=c++17
CFLAGS := -O2 -std=c++14 `pkg-config --cflags opencv4`
LDFLAGS := `pkg-config --libs opencv4` -lcudart

INCLUDES := -Iincludes
SRCS := src/main.cu src/image_utils.cpp
TARGET := textures_cuda

all:
	nvcc -O2 -std=c++17 `pkg-config --cflags opencv4` -Iincludes src/main.cu src/image_utils.cpp -o textures_cuda `pkg-config --libs opencv4` -lcudart

clean:
	rm -f $(TARGET)