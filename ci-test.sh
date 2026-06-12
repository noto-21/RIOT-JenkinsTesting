#!/bin/bash
set -e

echo "=== 1. Auditing Build System & Toolchains ==="
arm-none-eabi-gcc --version || echo "ARM GCC Toolchain not found"

echo "=== 2. Executing Firmware Compilation Test ==="
# Step 1: Actually enter the mounted Windows workspace!
cd /build

# Step 2: Navigate to the correctly categorized default example
cd examples/basic/default

# Step 3: Compile into Linux memory to bypass Windows I/O speed limits
echo "Compiling RIOT Firmware for 'native' target..."
make BOARD=native BUILD_DIR=/tmp/riot-build clean all

echo "========================================="
echo "   SUCCESS: RIOT Firmware Build Passed!  "
echo "========================================="
