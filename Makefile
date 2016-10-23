GPU=0
CUDNN=0
OPENCV=1
DEBUG=1

ARCH= --gpu-architecture=compute_52 --gpu-code=compute_52

# C Definitions

VPATH=./src/
EXEC=darknet
OBJDIR=./obj/
CC=gcc

# C++ Definitions
SRC_CPP=./src-cpp/
EXEC_CPP=darknet-cpp
OBJDIR_CPP=./obj-cpp/
CC_CPP=g++
CFLAGS_CPP=-Wno-write-strings

NVCC=nvcc
OPTS=-Ofast
LDFLAGS= -lm -pthread 
COMMON= 
CFLAGS=-Wall -Wfatal-errors 



ifeq ($(DEBUG), 1) 
OPTS=-O0 -g
endif

CFLAGS+=$(OPTS)

ifeq ($(OPENCV), 1) 
COMMON+= -DOPENCV
CFLAGS+= -DOPENCV
LDFLAGS+= `pkg-config --libs opencv` 
COMMON+= `pkg-config --cflags opencv` 
endif

# Place the IPP .a file from OpenCV here for easy linking
LDFLAGS += -L./3rdparty

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I/usr/local/cuda/include/
CFLAGS+= -DGPU
LDFLAGS+= -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

OBJ=gemm.o utils.o cuda.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o darknet.o detection_layer.o captcha.o route_layer.o writing.o box.o nightmare.o normalization_layer.o avgpool_layer.o coco.o dice.o yolo.o detector.o layer.o compare.o classifier.o local_layer.o swag.o shortcut_layer.o activation_layer.o rnn_layer.o gru_layer.o rnn.o rnn_vid.o crnn_layer.o demo.o tag.o cifar.o go.o batchnorm_layer.o art.o region_layer.o reorg_layer.o super.o voxel.o tree.o
ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o network_kernels.o avgpool_layer_kernels.o
endif

OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile

OBJS_CPP = $(addprefix $(OBJDIR_CPP), $(OBJ))
DEPS_CPP = $(wildcard src-cpp/*.h) Makefile

all: obj obj-cpp results $(EXEC) $(EXEC_CPP)

$(EXEC): $(OBJS)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(EXEC_CPP): $(OBJS_CPP)
	$(CC_CPP) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(OBJDIR_CPP)%.o: $(SRC_CPP)%.c $(DEPS_CPP)
	$(CC_CPP) $(COMMON) $(CFLAGS_CPP) $(CFLAGS) -c $< -o $@


$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

$(OBJDIR_CPP)%.o: $(SRC_CPP)%.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@


obj:
	mkdir -p obj
obj-cpp:
	mkdir -p obj-cpp

results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(EXEC)
	rm -rf $(OBJS_CPP) $(EXEC_CPP)

