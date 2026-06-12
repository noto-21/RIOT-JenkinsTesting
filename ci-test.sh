#!/bin/bash
set -e

echo "=== 1. Isolating Embedded Build Environment ==="
# Maintain our foolproof Windows-to-Docker volume isolation strategy
mkdir -p /native-build
cp -r /build/. /native-build
cd /native-build

echo "=== 2. Auditing Build System & Toolchains ==="
# Print the compiler version inside the Docker container for the logs
arm-none-eabi-gcc --version || echo "ARM GCC Toolchain not found, relying on native host compiler"

echo "=== 3. Executing Firmware Compilation Test ==="
# Navigate to the core default example application in RIOT
cd examples/default

# Compile the firmware for the native computer emulation board
# This tests the entire codebase structure without needing physical hardware!
echo "Compiling RIOT Firmware for 'native' target..."
make BOARD=native clean all

echo "========================================="
echo "   SUCCESS: RIOT Firmware Build Passed!  "
echo "========================================="
