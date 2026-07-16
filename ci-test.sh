#!/bin/bash
# Note: No 'set -e' here so a crash doesn't prematurely kill the CI pipeline!

LOG_PATH="/build/handler.log"

echo "=== 1. Auditing Environment & Toolchains ==="
# Install all required packages upfront
apt-get update -qq && apt-get install -y qemu-system-arm socat python3-requests

arm-none-eabi-gcc --version || echo "ARM GCC Toolchain not found"

echo "=== 2. Compiling RIOT Firmware ==="
cd /build/examples/basic/default || exit
echo "Compiling for 'microbit' (ARM Cortex-M0 QEMU target)..."

# TARGET FIX: Use the native 'microbit' board supported by RIOT
make BOARD=microbit -C /build/examples/basic/default

echo "=== 3. Executing QEMU Fault Injection ==="
echo "Booting VM... (Waiting 10 seconds to capture the crash)"

# Let QEMU write directly to the log file using '-serial file'
timeout 10 qemu-system-arm \
    -machine microbit \
    -nographic \
    -monitor none \
    -serial file:"$LOG_PATH" \
    -kernel /build/examples/basic/default/bin/microbit/default.elf
    
RIOT_EXIT_CODE=$?

# Exit code 124 means 'timeout' killed the process, which is exactly what is expected on a system lockup.
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
