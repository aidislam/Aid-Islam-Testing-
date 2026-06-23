/* Linker script for 32-bit kernel */

ENTRY(kernel_main)

SECTIONS
{
    . = 0x8000;
    
    .text :
    {
        *(.text)
    }
    
    .rodata :
    {
        *(.rodata)
    }
    
    .data :
    {
        *(.data)
    }
    
    .bss :
    {
        *(COMMON)
        *(.bss)
    }
}
