/*
 * Simple VGA Text Mode Driver
 * Prints characters to the screen at address 0xB8000
 * VGA text mode: 80x25 characters, 2 bytes per character (char + attribute)
 */

#include <stdint.h>
#include <stddef.h>
#include <limits.h>

/* VGA text mode memory address */
#define VGA_MEMORY 0xB8000

/* VGA dimensions */
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

/* VGA color attributes */
#define VGA_BLACK 0
#define VGA_BLUE 1
#define VGA_GREEN 2
#define VGA_CYAN 3
#define VGA_RED 4
#define VGA_MAGENTA 5
#define VGA_BROWN 6
#define VGA_LIGHT_GRAY 7
#define VGA_DARK_GRAY 8
#define VGA_LIGHT_BLUE 9
#define VGA_LIGHT_GREEN 10
#define VGA_LIGHT_CYAN 11
#define VGA_LIGHT_RED 12
#define VGA_LIGHT_MAGENTA 13
#define VGA_YELLOW 14
#define VGA_WHITE 15

/* Global cursor position */
static uint16_t cursor_x = 0;
static uint16_t cursor_y = 0;
static uint8_t text_color = (VGA_WHITE << 4) | VGA_BLACK;

/* VGA entry structure */
typedef struct {
    uint8_t character;
    uint8_t color;
} vga_entry_t;

/*
 * Get VGA entry at position (x, y)
 */
static vga_entry_t* vga_get_entry(uint16_t x, uint16_t y) {
    return (vga_entry_t*)(VGA_MEMORY + 2 * (y * VGA_WIDTH + x));
}

/*
 * Clear the screen with a given color
 */
void vga_clear_screen(uint8_t color) {
    vga_entry_t* entry;
    
    for (uint16_t y = 0; y < VGA_HEIGHT; y++) {
        for (uint16_t x = 0; x < VGA_WIDTH; x++) {
            entry = vga_get_entry(x, y);
            entry->character = ' ';
            entry->color = color;
        }
    }
    
    cursor_x = 0;
    cursor_y = 0;
}

/*
 * Scroll screen up by one line
 */
static void vga_scroll_up(void) {
    vga_entry_t* src;
    vga_entry_t* dst;
    
    /* Move all lines up by one */
    for (uint16_t y = 0; y < VGA_HEIGHT - 1; y++) {
        for (uint16_t x = 0; x < VGA_WIDTH; x++) {
            src = vga_get_entry(x, y + 1);
            dst = vga_get_entry(x, y);
            dst->character = src->character;
            dst->color = src->color;
        }
    }
    
    /* Clear bottom line */
    for (uint16_t x = 0; x < VGA_WIDTH; x++) {
        dst = vga_get_entry(x, VGA_HEIGHT - 1);
        dst->character = ' ';
        dst->color = text_color;
    }
    
    /* Prevent cursor underflow */
    if (cursor_y > 0) {
        cursor_y--;
    }
}

/*
 * Handle newline - move cursor to next line
 */
static void vga_newline(void) {
    cursor_x = 0;
    cursor_y++;
    
    if (cursor_y >= VGA_HEIGHT) {
        vga_scroll_up();
    }
}

/*
 * Put a single character at current cursor position
 */
void vga_putchar(char c) {
    vga_entry_t* entry;
    
    if (c == '\n') {
        vga_newline();
        return;
    }
    
    if (c == '\r') {
        cursor_x = 0;
        return;
    }
    
    if (c == '\t') {
        /* Align to next tab stop (4-byte boundary) */
        cursor_x = (cursor_x + 4) & ~3;
        if (cursor_x >= VGA_WIDTH) {
            vga_newline();
        }
        return;
    }
    
    /* Write character to VGA memory */
    entry = vga_get_entry(cursor_x, cursor_y);
    entry->character = (unsigned char)c;
    entry->color = text_color;
    
    /* Move cursor to next position */
    cursor_x++;
    if (cursor_x >= VGA_WIDTH) {
        vga_newline();
    }
}

/*
 * Print a null-terminated string
 */
void vga_puts(const char* str) {
    if (str == NULL) {
        return;
    }
    
    while (*str) {
        vga_putchar(*str);
        str++;
    }
}

/*
 * Set text color (foreground in lower 4 bits, background in upper 4 bits)
 */
void vga_set_color(uint8_t foreground, uint8_t background) {
    text_color = (background << 4) | foreground;
}

/*
 * Get current cursor position
 */
void vga_get_cursor(uint16_t* x, uint16_t* y) {
    if (x != NULL) {
        *x = cursor_x;
    }
    if (y != NULL) {
        *y = cursor_y;
    }
}

/*
 * Set cursor position
 */
void vga_set_cursor(uint16_t x, uint16_t y) {
    if (x < VGA_WIDTH && y < VGA_HEIGHT) {
        cursor_x = x;
        cursor_y = y;
    }
}

/*
 * Print an integer as decimal
 */
void vga_print_int(int32_t num) {
    if (num == 0) {
        vga_putchar('0');
        return;
    }
    
    if (num < 0) {
        vga_putchar('-');
        /* Handle INT32_MIN special case to prevent overflow */
        if (num == INT32_MIN) {
            vga_puts("2147483648");
            return;
        }
        num = -num;
    }
    
    /* Get digits in reverse order */
    char buffer[16] = {0};
    int index = 0;
    
    while (num > 0 && index < 15) {
        buffer[index++] = '0' + (num % 10);
        num /= 10;
    }
    
    /* Print in correct order */
    while (index > 0) {
        vga_putchar(buffer[--index]);
    }
}

/*
 * Print a hexadecimal number
 */
void vga_print_hex(uint32_t num) {
    const char* hex_chars = "0123456789ABCDEF";
    
    vga_puts("0x");
    
    for (int i = 28; i >= 0; i -= 4) {
        vga_putchar(hex_chars[(num >> i) & 0xF]);
    }
}
