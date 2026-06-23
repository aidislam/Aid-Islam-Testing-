/* Simple 32-bit Kernel in C */

/* VGA Video Memory */
#define VIDEO_MEMORY 0xB8000
#define MAX_ROWS 25
#define MAX_COLS 80

/* VGA Colors */
#define BLACK 0
#define WHITE 15
#define GREEN 2

/* Current cursor position */
static int cursor_row = 0;
static int cursor_col = 0;

/* Helper function to write a character to video memory */
void write_char(char c, int row, int col, char attr)
{
    volatile unsigned char *video = (unsigned char *)VIDEO_MEMORY;
    int offset = (row * MAX_COLS + col) * 2;
    
    video[offset] = (unsigned char)c;      /* Character */
    video[offset + 1] = attr;               /* Attribute (color) */
}

/* Print a single character */
void putchar(char c)
{
    if (c == '\n') {
        cursor_row++;
        cursor_col = 0;
    } else if (c == '\r') {
        cursor_col = 0;
    } else {
        write_char(c, cursor_row, cursor_col, 
                  (WHITE << 4) | BLACK);   /* White text on black background */
        cursor_col++;
    }
    
    /* Wrap to next line if needed */
    if (cursor_col >= MAX_COLS) {
        cursor_row++;
        cursor_col = 0;
    }
    
    /* Scroll if we go past the last row */
    if (cursor_row >= MAX_ROWS) {
        cursor_row = MAX_ROWS - 1;
        scroll_screen();
    }
}

/* Scroll the screen up by one line */
void scroll_screen(void)
{
    volatile unsigned char *video = (unsigned char *)VIDEO_MEMORY;
    int row, col;
    
    /* Move each row up */
    for (row = 0; row < MAX_ROWS - 1; row++) {
        for (col = 0; col < MAX_COLS; col++) {
            int from = ((row + 1) * MAX_COLS + col) * 2;
            int to = (row * MAX_COLS + col) * 2;
            video[to] = video[from];
            video[to + 1] = video[from + 1];
        }
    }
    
    /* Clear the last row */
    for (col = 0; col < MAX_COLS; col++) {
        write_char(' ', MAX_ROWS - 1, col, 
                  (WHITE << 4) | BLACK);
    }
}

/* Print a string */
void print(const char *str)
{
    int i = 0;
    while (str[i] != '\0') {
        putchar(str[i]);
        i++;
    }
}

/* Print an integer */
void print_int(int num)
{
    if (num < 0) {
        putchar('-');
        num = -num;
    }
    
    if (num == 0) {
        putchar('0');
        return;
    }
    
    char buffer[32];
    int index = 0;
    
    while (num > 0) {
        buffer[index++] = '0' + (num % 10);
        num /= 10;
    }
    
    while (index > 0) {
        putchar(buffer[--index]);
    }
}

/* Main kernel entry point */
void main(void)
{
    /* Print welcome message */
    print("Hello OS\n");
    print("\nWelcome to Simple 32-bit OS!\n");
    print("Kernel initialized successfully.\n\n");
    
    /* Print system info */
    print("System Information:\n");
    print("- Architecture: i386 (32-bit)\n");
    print("- Video Mode: 80x25 Text\n");
    print("- Video Memory: 0xB8000\n");
    print("- Kernel Base: 0x10000\n\n");
    
    /* Simple loop to demonstrate the kernel is running */
    print("Kernel is running. Waiting for input...\n");
    
    /* Infinite loop - kernel keeps running */
    while (1) {
        asm("hlt");  /* Halt CPU until next interrupt */
    }
}
