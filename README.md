# Simple 32-bit Operating System

A minimalist 32-bit OS built from scratch with an assembly bootloader and C kernel.

## Project Structure

```
.
├── boot.asm          # 16-bit bootloader (BIOS/MBR)
├── kernel.c          # Simple 32-bit kernel
├── kernel.asm        # Assembly entry point and low-level kernel code
├── Makefile          # Build automation
├── linker.ld         # Linker script
└── README.md         # This file
```

## Prerequisites

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install build-essential nasm qemu-system-x86
```

### macOS
```bash
brew install nasm qemu
```

### Windows
Download and install:
- [NASM](https://www.nasm.us/)
- [MinGW](https://www.mingw-w64.org/) or use WSL
- [QEMU](https://www.qemu.org/)

## Building the OS

```bash
# Build everything
make

# Clean build
make clean

# Run in QEMU
make run

# Debug in QEMU
make debug
```

## How It Works

1. **Boot Stage** (boot.asm):
   - BIOS loads the 512-byte bootloader from disk sector 0
   - Bootloader switches from 16-bit real mode to 32-bit protected mode
   - Loads kernel into memory and jumps to kernel entry point

2. **Kernel Stage** (kernel.asm + kernel.c):
   - Sets up Global Descriptor Table (GDT)
   - Configures interrupt handlers
   - Initializes video memory for text output
   - Prints "Hello OS" to the screen

## Output

When you run `make run`, the OS boots in QEMU and displays:
```
Hello OS
```

## References

- [OSDev Wiki](https://wiki.osdev.org/)
- [i386 Architecture Manual](https://wiki.osdev.org/CPU_Manual)
- [BIOS/MBR Boot Process](https://wiki.osdev.org/Boot_sequence)
