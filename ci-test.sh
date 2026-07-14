#!/bin/bash
# Note: No 'set -e' here so a crash doesn't prematurely kill the CI pipeline!

LOG_PATH="/build/handler.log"

echo "=== 1. Auditing Environment & Toolchains ==="
# Install all required packages upfront
apt-get update -qq && apt-get install -y qemu-system-arm socat python3-requests

arm-none-eabi-gcc --version || echo "ARM GCC Toolchain not found"

echo "=== 2. Compiling RIOT Firmware ==="
cd /build/examples/basic/default || exit
echo "Compiling for 'microbit' (ARM Cortex-M0) target..."
make BOARD=microbit clean all

echo "=== 3. Executing QEMU Fault Injection ==="
# Use the 'timeout' command because a HardFault causes RIOT to lock up natively.
echo "Booting VM... (Waiting 10 seconds to capture the crash)"

# stdbuf -o0 -e0 disables output buffering entirely.
# This guarantees that even when QEMU is killed by timeout, the log is already written.
timeout 10 stdbuf -o0 -e0 qemu-system-arm \
    -machine microbit \
    -nographic \
    -monitor none \
    -serial stdio \
    -device loader,file=/build/examples/basic/default/bin/microbit/default.elf > "$LOG_PATH" 2>&1
    
RIOT_EXIT_CODE=$?

# exit code 124 means 'timeout' killed the process, which is exactly what is expected on a system lockup.
if [ $RIOT_EXIT_CODE -eq 124 ] || [ $RIOT_EXIT_CODE -ne 0 ]; then
    echo "WARNING: System locked up or crashed! Capturing telemetry..."
    
    if [ -f "$LOG_PATH" ]; then
        echo "=== RAW QEMU OUTPUT ==="
        cat "$LOG_PATH"
        echo "======================="

        echo "Invoking ESOps LLaMA Fault Detection Engine..."
        # Pass the RIOT crash log to the AI
        python3 /build/esops_analyzer.py "$LOG_PATH" "RIOT"
    else
        echo "No crash log generated."
    fi
    
    # Exit with failure to maintain pipeline integrity
    exit 1
fi

echo "========================================="
echo "   SUCCESS: RIOT Firmware Build Passed!  "
echo "========================================="
