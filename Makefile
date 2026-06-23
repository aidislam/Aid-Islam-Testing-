# Makefile for Simple 32-bit OS

# Compiler and tools
CC = i686-elf-gcc
AS = nasm
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

# Flags
CFLAGS = -ffreestanding -nostdlib -fno-builtin -m32 -c -Wall
ASFLAGS = -f elf32
LDFLAGS = -T linker.ld -m elf_i386

# Output files
BOOTLOADER = boot.bin
KERNEL_OBJ = kernel.o kernel_asm.o
KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
OS_IMAGE = os.img

# Phony targets
.PHONY: all clean run debug help

all: $(OS_IMAGE)

# Build bootloader
$(BOOTLOADER): boot.asm
	$(AS) -f bin -o $@ $<

# Build kernel assembly
kernel_asm.o: kernel.asm
	$(AS) $(ASFLAGS) -o $@ $<

# Build kernel C code
kernel.o: kernel.c
	$(CC) $(CFLAGS) -o $@ $<

# Link kernel
$(KERNEL_ELF): kernel_asm.o kernel.o
	$(LD) $(LDFLAGS) -o $@ $^

# Convert kernel ELF to binary
$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

# Create OS image (bootloader + kernel)
$(OS_IMAGE): $(BOOTLOADER) $(KERNEL_BIN)
	# Combines bootloader and kernel directly into one image
	cat $(BOOTLOADER) $(KERNEL_BIN) > $@
	# Pad to standard 1.44MB floppy size safely
	truncate -s 1440k $@

# Run in QEMU
run: $(OS_IMAGE)
	qemu-system-i386 -fda $< -boot a

# Debug in QEMU with GDB
debug: $(OS_IMAGE)
	qemu-system-i386 -fda $< -boot a -s -S &
	gdb -ex "target remote localhost:1234" -ex "symbol-file $(KERNEL_ELF)"

# Clean build files
clean:
	rm -f $(BOOTLOADER) $(KERNEL_ELF) $(KERNEL_BIN) $(KERNEL_OBJ) $(OS_IMAGE)
	rm -f *.o *.elf *.bin *.img

# Help target
help:
	@echo "Available targets:"
	@echo "  make all    - Build the OS image"
	@echo "  make run    - Build and run in QEMU"
	@echo "  make debug  - Build and debug with GDB in QEMU"
	@echo "  make clean  - Remove all build files"
	@echo "  make help   - Show this help message"
