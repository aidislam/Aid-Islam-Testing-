# Build and Setup Guide for 32-bit OS

## Quick Start

### 1. Install Cross-Compiler (i686-elf-gcc)

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install build-essential nasm qemu-system-x86 wget
```

**For i686-elf-gcc (cross-compiler):**
```bash
# Option 1: Using package manager (if available)
sudo apt-get install gcc-i686-linux-gnu binutils-i686-linux-gnu

# Option 2: Build from source (more reliable)
cd /tmp
mkdir build-cross && cd build-cross
wget https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
tar -xf binutils-2.37.tar.xz
tar -xf gcc-11.2.0.tar.xz

# Build binutils
cd binutils-2.37
./configure --target=i686-elf --prefix=/usr/local/i686-elf
make
sudo make install
cd ..

# Build GCC
cd gcc-11.2.0
./configure --target=i686-elf --prefix=/usr/local/i686-elf --disable-nls --enable-languages=c
make all-gcc
sudo make install-gcc
cd ..
```

**macOS:**
```bash
brew install nasm qemu i686-elf-gcc
```

**Windows (WSL or MinGW):**
Use WSL with Ubuntu instructions above.

---

### 2. Build the OS

```bash
# Clone/navigate to repository
cd Aid-Islam-Testing-

# Build the OS image
make

# Clean previous builds
make clean
```

**What gets built:**
- `boot.bin` - 512-byte bootloader
- `kernel.o` - Compiled C kernel code
- `kernel_asm.o` - Compiled assembly kernel
- `kernel.elf` - Linked kernel executable
- `kernel.bin` - Binary kernel
- `os.img` - Final bootable OS image

---

### 3. Run in QEMU

```bash
# Run the OS
make run

# This command starts QEMU emulating an i386 PC
# You should see:
# "Booting OS..."
# "Kernel loaded. Entering protected mode..."
# "Hello OS"
# "Welcome to Simple 32-bit OS!"
```

---

### 4. Debug with GDB

```bash
# Terminal 1: Start QEMU in debug mode
make debug

# Terminal 2: Connect GDB
gdb
(gdb) target remote localhost:1234
(gdb) symbol-file kernel.elf
(gdb) break main
(gdb) continue
(gdb) step       # Step through code
(gdb) info registers   # View CPU registers
(gdb) x/10i $eip       # View instructions at EIP
```

---

## File Structure and Explanation

### `boot.asm` - 16-bit Bootloader
- **Entry Point:** BIOS loads this at 0x7C00
- **Functions:**
  - Initializes segment registers
  - Sets 80x25 text mode
  - Loads GDT (Global Descriptor Table)
  - Enables A20 line (for >1MB memory access)
  - Switches CPU from 16-bit real mode → 32-bit protected mode
  - Loads kernel into memory at 0x10000
  - Jumps to kernel entry point

### `kernel.asm` - 32-bit Kernel Entry
- **Function:** `kernel_main`
  - Clears video memory (fills screen with spaces)
  - Calls C function `main()`
  - Infinite halt loop

### `kernel.c` - C Kernel Implementation
- **Key Functions:**
  - `main()` - Kernel entry point
  - `putchar()` - Print single character to screen
  - `print()` - Print string
  - `print_int()` - Print integer
  - `write_char()` - Write to VGA memory
  - `scroll_screen()` - Scroll text when reaching bottom
- **Video Memory:** 0xB8000 (80x25 text mode)

### `linker.ld` - Linker Script
- Maps sections (.text, .data, .bss)
- Sets kernel base address to 0x10000
- Aligns sections on 4KB boundaries

### `Makefile` - Build Automation
```makefile
make all     # Build os.img
make clean   # Remove build files
make run     # Run in QEMU
make debug   # Run with GDB support
make help    # Show help
```

---

## How the Boot Process Works

```
1. BIOS starts → Loads boot.asm at 0x7C00
                 ↓
2. Bootloader initialization (real mode)
   - Clear interrupts
   - Initialize segment registers
   - Set stack at 0x7C00
                 ↓
3. Load kernel from disk (sectors 2-5)
   - Destination: 0x1000:0x0000 (0x10000 physical)
                 ↓
4. Enable A20 line (memory access >1MB)
                 ↓
5. Load GDT (Global Descriptor Table)
                 ↓
6. Set PE bit in CR0 (enter protected mode)
                 ↓
7. Far jump to 32-bit code (0x08:pm_entry)
   - CPU now in 32-bit protected mode
                 ↓
8. Set up data segments and stack
                 ↓
9. Jump to kernel at 0x10000
                 ↓
10. kernel_main() - Clear screen, call main()
                 ↓
11. main() - Print messages, infinite loop
```

---

## Troubleshooting

### Build Errors

**Error: `command not found: i686-elf-gcc`**
```bash
# Set PATH for cross-compiler
export PATH=$PATH:/usr/local/i686-elf/bin
```

**Error: `error: stdio.h: No such file`**
- Remove `#include <stdio.h>` - this is bare metal, no standard library
- Use custom `print()` function instead

**Error: `Disk read error`**
- Check bootloader size (must be ≤ 512 bytes)
- Verify kernel loading address in boot.asm

### Runtime Issues

**Screen shows garbage instead of text**
- Check VGA memory access at 0xB8000
- Verify attribute byte format: `(foreground << 4) | background`

**Kernel doesn't start**
- Check linker script - kernel must be at 0x10000
- Verify GDT is properly initialized
- Check stack setup in protected mode

---

## Extending the OS

### Add Interrupt Handler
```asm
; In kernel.asm
extern idt_install
call idt_install
```

### Add Keyboard Support
```c
// In kernel.c
void keyboard_handler() {
    unsigned char scancode = inb(0x60);
    // Handle keyboard input
}
```

### Add Memory Management
```c
void* malloc(int size) {
    // Simple memory allocator
}

void free(void* ptr) {
    // Free memory
}
```

### Add File System Support
```c
void read_sector(int sector, void* buffer) {
    // Read disk sector
}
```

---

## Useful QEMU Commands

```bash
# Run with different display
qemu-system-i386 -fda os.img -display curses

# Run with more memory
qemu-system-i386 -fda os.img -m 256

# Run with serial output (debug)
qemu-system-i386 -fda os.img -serial stdio

# Run from hard disk image
qemu-system-i386 -drive format=raw,file=os.img
```

---

## References

- [OSDev.org](https://wiki.osdev.org/) - OS Development Resources
- [i386 Instruction Set](https://www.felixcloutier.com/x86/)
- [NASM Documentation](https://www.nasm.us/doc/)
- [GCC Inline Assembly](https://gcc.gnu.org/onlinedocs/gcc/Using-Inline-Assembly-with-C.html)
- [QEMU Documentation](https://qemu.readthedocs.io/)

---

## License

This project is provided as educational material for learning OS development.
