; Simple 32-bit Kernel - Assembly Entry Point
; Handles basic initialization before calling C code

[BITS 32]
[GLOBAL kernel_main]
[EXTERN main]

kernel_main:
    ; Clear screen by filling video memory with spaces
    mov edi, 0xB8000        ; Video memory base address (80x25 text mode)
    mov ecx, 2000           ; 80 * 25 = 2000 characters
    mov ax, 0x0F20          ; Attribute: white on black, character: space
    rep stosw               ; Fill video memory
    
    ; Call C kernel main function
    call main
    
    ; Infinite loop
.hang:
    hlt
    jmp .hang

; Stack and other kernel data
section .bss
    align 0x1000
    kernel_stack:
        resb 0x4000         ; 16KB kernel stack
