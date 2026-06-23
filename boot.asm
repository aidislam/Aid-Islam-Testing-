; Simple 32-bit OS Bootloader
; This bootloader runs in 16-bit real mode and switches to 32-bit protected mode
; Assembled with NASM

[BITS 16]
[ORG 0x7C00]

; BIOS entry point
boot_start:
    cli                     ; Clear interrupts
    cld                     ; Clear direction flag
    
    ; Initialize segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          ; Set stack pointer
    
    ; Clear screen using BIOS
    mov ax, 0x0003          ; Set 80x25 text mode
    int 0x10
    
    ; Print "Booting..." message
    mov si, boot_msg
    call print_string_16
    
    ; Load kernel from disk
    mov ax, 0x1000          ; Load kernel at 0x1000:0x0000
    mov es, ax
    xor bx, bx              ; es:bx = destination
    
    mov ah, 0x02            ; BIOS read sectors function
    mov al, 4               ; Read 4 sectors (2KB)
    mov ch, 0               ; Cylinder 0
    mov cl, 2               ; Start at sector 2 (bootloader is sector 1)
    mov dh, 0               ; Head 0
    mov dl, 0x00            ; Fixed: Set to 0x00 for First Floppy Drive (Emulator Support)
    int 0x13
    
    jc disk_error           ; Jump if carry flag set (error)
    
    ; Print "Loaded." message
    mov si, loaded_msg
    call print_string_16
    
    ; ============= SWITCH TO 32-BIT PROTECTED MODE =============
    
    ; Load GDT
    lgdt [gdt_descriptor]
    
    ; Enable A20 line (for accessing >1MB memory)
    call enable_a20
    
    ; Set PE (Protection Enable) bit in CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump to 32-bit code (flush pipeline)
    jmp 0x08:pm_entry       ; Code segment selector = 0x08
    
disk_error:
    mov si, error_msg
    call print_string_16
    hlt
    
; ============= 16-BIT REAL MODE FUNCTIONS =============

; Print string in 16-bit mode
; Input: ds:si = string pointer
print_string_16:
.loop:
    lodsb                   ; Load byte from [ds:si] into al, increment si
    test al, al             ; Check for null terminator
    jz .done
    
    mov ah, 0x0E            ; BIOS write character function
    mov bh, 0               ; Page 0
    int 0x10
    jmp .loop
.done:
    ret

; Enable A20 line using keyboard controller
enable_a20:
    cli
    
    ; Disable keyboard
    mov al, 0xAD
    out 0x64, al
    
    ; Read current output port
    mov al, 0xD0
    out 0x64, al
    in al, 0x60
    push ax
    
    ; Write output port with A20 enabled
    mov al, 0xD1
    out 0x64, al
    pop ax
    or al, 0x02             ; Set A20 bit
    out 0x60, al
    
    ; Enable keyboard
    mov al, 0xAE
    out 0x64, al
    
    sti
    ret

; ============= 16-BIT DATA =============

boot_msg: db "Booting OS...", 0x0D, 0x0A, 0
loaded_msg: db "Kernel loaded. Entering protected mode...", 0x0D, 0x0A, 0
error_msg: db "Disk error!", 0x0D, 0x0A, 0

; ============= GDT (Global Descriptor Table) =============

gdt_start:
    ; Null descriptor (required)
    dq 0
    
    ; Code segment descriptor
    dw 0xFFFF               ; Limit (low 16 bits)
    dw 0x0000               ; Base (low 16 bits)
    db 0x00                 ; Base (middle 8 bits)
    db 0x9A                 ; Flags: Present, Privilege 0, Code, Execute/Read
    db 0xCF                 ; Flags: 4KB granularity, 32-bit
    db 0x00                 ; Base (high 8 bits)
    
    ; Data segment descriptor
    dw 0xFFFF               ; Limit (low 16 bits)
    dw 0x0000               ; Base (low 16 bits)
    db 0x00                 ; Base (middle 8 bits)
    db 0x92                 ; Flags: Present, Privilege 0, Data, Read/Write
    db 0xCF                 ; Flags: 4KB granularity, 32-bit
    db 0x00                 ; Base (high 8 bits)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                 ; Address of GDT

; ============= 32-BIT PROTECTED MODE ENTRY =============

[BITS 32]

pm_entry:
    ; Set up data segment selectors
    mov ax, 0x10            ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov esp, 0x90000
    
    ; Call kernel
    call 0x10000
    
    ; Halt if kernel returns
    hlt

; ============= PADDING AND BOOT SIGNATURE =============
times 510 - ($ - $$) db 0
dw 0xAA55               ; Boot signature

