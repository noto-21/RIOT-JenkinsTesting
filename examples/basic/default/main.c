#include <stdio.h>
#include <stdint.h>
#include "board.h"
#include "thread.h"

int main(void)
{
    puts("\n=== ESOps RIOT OS Hardware Fault Injection ===");
    puts("Booting on ARM Cortex-M architecture...");
    puts("Injecting a Null Pointer Dereference (NPD)...\n");

    /* Force the CPU to waste time so the UART can finish printing */
    for (volatile uint32_t i = 0; i < 50000; i++) {
        __asm__("nop"); // No-operation
    }

    /* Create a function pointer to an invalid memory address */
    void (*bad_function)(void) = (void (*)(void))0x00000000;

    /* Execute the invalid address. */
    bad_function();

    puts("FAIL: The CPU should have crashed before reaching this line!");
    return 0;
}
