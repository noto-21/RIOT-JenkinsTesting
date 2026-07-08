#!/bin/bash
# Note: No 'set -e' here so a crash doesn't prematurely kill the CI pipeline!

LOG_PATH="/build/handler.log"

echo "=== 1. Auditing Environment & Toolchains ==="
arm-none-eabi-gcc --version || echo "ARM GCC Toolchain not found"

# Ensure QEMU is installed in the riotbuild container
if ! command -v qemu-system-arm &> /dev/null; then
    echo "Installing QEMU for ARM emulation..."
    apt-get update -qq && apt-get install -y qemu-system-arm
fi

echo "=== 2. Compiling RIOT Firmware ==="
cd /build/examples/basic/default || exit
echo "Compiling for 'microbit' (ARM Cortex-M0) target..."
make BOARD=microbit clean all

echo "=== 3. Executing QEMU Fault Injection ==="
# We use the 'timeout' command because a HardFault causes RIOT to lock up natively.
# We redirect both stdout and stderr to our log file for LLaMA to read.
echo "Booting VM... (Waiting 10 seconds to capture the crash)"
timeout 10 make BOARD=microbit EMULATE=1 term > "$LOG_PATH" 2>&1
RIOT_EXIT_CODE=$?

# exit code 124 means 'timeout' killed the process, which is exactly what we expect on a system lockup.
if [ $RIOT_EXIT_CODE -eq 124 ] || [ $RIOT_EXIT_CODE -ne 0 ]; then
    echo "WARNING: System locked up or crashed! Capturing telemetry..."
    
    if [ -f "$LOG_PATH" ]; then
        echo "Invoking ESOps LLaMA Fault Detection Engine..."
        # Ensure dependencies are available in the container
        apt-get install -y python3-pip
        pip3 install requests --quiet
        
        # Pass the RIOT crash log to the AI
        python3 /build/esops_analyzer.py "$LOG_PATH"
    else
        echo "No crash log generated."
    fi
    
    # Exit with failure to maintain pipeline integrity
    exit 1
fi

echo "========================================="
echo "   SUCCESS: RIOT Firmware Build Passed!  "
echo "========================================="
