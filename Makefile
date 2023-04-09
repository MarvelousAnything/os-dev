ASM=nasm
CC=gcc

SRC_DIR=./src
TOOLS_DIR=./tools
BUILD_DIR=./build

.PHONY: all floppy_image kernel bootloader clean always

all: floppy_image tools

test_tools: all
	$(BUILD_DIR)/tools/fat/fat $(BUILD_DIR)/main_floppy.img "TEST    TXT"

run: clean floppy_image
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img -vga cirrus

#
# Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	# dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.dmg bs=512 count=2880
	hdiutil create -size 1440k -fs "MS-DOS FAT12" -layout NONE -volname BSOS $(BUILD_DIR)/main_floppy.dmg
	mv $(BUILD_DIR)/main_floppy.dmg $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img ./test.txt "::test.txt"


#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -g -o $(BUILD_DIR)/bootloader.bin

symbols: $(BUILD_DIR)/bootloader.elf

$(BUILD_DIR)/bootloader.elf: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f elf -F dwarf -g -o $(BUILD_DIR)/bootloader.elf

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -g -o $(BUILD_DIR)/kernel.bin


#
# Tools
#
tools: $(BUILD_DIR)/tools/fat/fat

$(BUILD_DIR)/tools/fat/fat: always
	mkdir -p $(BUILD_DIR)/tools/fat
	$(CC) $(TOOLS_DIR)/fat/fat.h $(TOOLS_DIR)/fat/fat.c -g -o $(BUILD_DIR)/tools/fat/fat

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

#
# Clean
#
clean:
	rm -rf $(BUILD_DIR)/*

	
