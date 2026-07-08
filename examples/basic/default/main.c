#include <stdio.h>
#include "board.h"
#include "thread.h"

int main(void) {
    puts("\n=== ESOps RIOT OS Hardware Fault Injection ===");
    puts("Booting on ARM Cortex-M architecture...");
    puts("Injecting a Null Pointer Dereference (NPD)...\n");

    /* Create a function pointer to an invalid memory address */
    void (*bad_function)(void) = (void (*)(void))0x00000000;

    /* Execute the invalid address. 
     * The Cortex-M CPU will HardFault, and RIOT's kernel will print the registers.
     */
    bad_function();

    puts("FAIL: The CPU should have crashed before reaching this line!");
    return 0;
}
