#!/bin/bash
set -e

echo "=== 1. Auditing Build System & Toolchains ==="
# Verify the RIOT Docker image has our ARM compiler ready to go
arm-none-eabi-gcc --version || echo "ARM GCC Toolchain not found"

echo "=== 2. Executing Firmware Compilation Test ==="
# Navigate to the correctly categorized default example
cd examples/basic/default

# We use BUILD_DIR=/tmp/riot-build to send all compiled binary artifacts 
# directly to the lightning-fast Linux memory space, bypassing Windows NTFS entirely!
echo "Compiling RIOT Firmware for 'native' target..."
make BOARD=native BUILD_DIR=/tmp/riot-build clean all

echo "========================================="
echo "   SUCCESS: RIOT Firmware Build Passed!  "
echo "========================================="
