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
    mov al, 8               ; Read 8 sectors to be safe
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

enable_a20:
    cli
    mov al, 0xAD
    out 0x64, al
    mov al, 0xD0
    out 0x64, al
    in al, 0x60
    push ax
    mov al, 0xD1
    out 0x64, al
    pop ax
    or al, 0x02             ; Set A20 bit
    out 0x60, al
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
    dq 0
gdt_code:
    dw 0xFFFF               
    dw 0x0000               
    db 0x00                 
    db 0x9A                 
    db 0xCF                 
    db 0x00                 
gdt_data:
    dw 0xFFFF               
    dw 0x0000               
    db 0x00                 
    db 0x92                 
    db 0xCF                 
    db 0x00                 
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  
    dd gdt_start                 

; ============= 32-BIT PROTECTED MODE ENTRY =============

[BITS 32]

pm_entry:
    ; Set up data segment selectors
    mov ax, 0x10            ; Data segment selector (gdt_data offset)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov esp, 0x90000
    
    ; FIXED: সরাসরি ebx রেজিস্টারে Absolute Address নিয়ে কল করা হলো
    mov ebx, 0x10000
    call ebx
    
    ; Halt if kernel returns
    hlt

; ============= PADDING AND BOOT SIGNATURE =============
times 510 - ($ - $$) db 0
dw 0xAA55               

