; Minimal 16-bit Real Mode Bootloader
; Prints "My OS is Loading..." and hangs
; Assemble with: nasm bootloader.asm -o bootloader.bin

bits 16
org 0x7c00

start:
    ; Initialize segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Print message
    mov si, message
    call print_string

    ; Hang
    jmp $

print_string:
    ; Print string pointed to by SI
    ; Uses BIOS interrupt 0x10
    lodsb                   ; Load byte from DS:SI into AL, increment SI
    test al, al             ; Check for null terminator
    jz .done                ; If zero, we're done
    
    mov ah, 0x0e           ; BIOS teletype function
    mov bh, 0              ; Page number
    int 0x10               ; Call BIOS video interrupt
    jmp print_string       ; Continue with next character

.done:
    ret

message:
    db "My OS is Loading...", 0

; Pad to 510 bytes with zeros
times 510 - ($ - $$) db 0

; Boot signature (required for bootable media)
dw 0xaa55
