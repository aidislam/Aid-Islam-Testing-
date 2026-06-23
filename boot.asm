; Simple 32-bit OS Bootloader
; Assembled with NASM

[BITS 16]
[ORG 0x7C00]

boot_start:
    cli                     
    cld                     
    
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          
    
    ; Clear screen
    mov ax, 0x0003          
    int 0x10
    
    mov si, boot_msg
    call print_string_16
    
    ; Load kernel from disk directly to segment 0x0000 at offset 0x8000
    xor ax, ax
    mov es, ax
    mov bx, 0x8000          ; es:bx = 0x0000:0x8000 (Physical Address: 0x8000)
    
    mov ah, 0x02            
    mov al, 15              ; Read 15 sectors to ensure full kernel is loaded
    mov ch, 0               
    mov cl, 2               
    mov dh, 0               
    mov dl, 0x00            ; Floppy Drive
    int 0x13
    
    jc disk_error           
    
    mov si, loaded_msg
    call print_string_16
    
    ; Switch to Protected Mode
    lgdt [gdt_descriptor]
    call enable_a20
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    jmp 0x08:pm_entry       

disk_error:
    mov si, error_msg
    call print_string_16
    hlt
    
print_string_16:
.loop:
    lodsb                   
    test al, al             
    jz .done
    mov ah, 0x0E            
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
    or al, 0x02             
    out 0x60, al
    mov al, 0xAE
    out 0x64, al
    sti
    ret

boot_msg: db "Booting OS...", 0x0D, 0x0A, 0
loaded_msg: db "Kernel loaded. Entering 32-bit PM...", 0x0D, 0x0A, 0
error_msg: db "Disk error!", 0x0D, 0x0A, 0

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

[BITS 32]
pm_entry:
    mov ax, 0x10            
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    mov esp, 0x90000
    
    ; Jump to Kernel Base at 0x8000
    mov ebx, 0x8000
    jmp ebx

times 510 - ($ - $$) db 0
dw 0xAA55               

