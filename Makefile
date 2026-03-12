FASM      := fasm
CC        := gcc

SRC_DIR   := SOURCE
ENTRY     := $(SRC_DIR)/NUSAOS/FASM.ASM
BUILD_DIR := build
OBJ       := $(BUILD_DIR)/fasm_asm.o
TARGET    := fasm

CFLAGS    := -m32 -fno-pic -no-pie -static -fno-stack-protector

INC_FILES := $(wildcard $(SRC_DIR)/*.INC) \
             $(wildcard $(SRC_DIR)/*.inc) \
             $(wildcard $(SRC_DIR)/NUSAOS/*.INC) \
             $(wildcard $(SRC_DIR)/NUSAOS/*.inc)

.PHONY: all clean

all: $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ): $(ENTRY) $(INC_FILES) | $(BUILD_DIR)
	$(FASM) $(ENTRY) $(OBJ)

$(TARGET): $(OBJ) stub.c
	$(CC) $(CFLAGS) stub.c $(OBJ) -o $(TARGET)

clean:
	rm -rf $(BUILD_DIR) $(TARGET)