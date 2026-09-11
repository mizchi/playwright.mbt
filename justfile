# MoonBit Project Commands

# Default target (js for browser compatibility)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Type check
check:
    moon check --deny-warn --target {{target}}

# Type check (native)
check-native:
    moon check --deny-warn --target native

# Run tests
test:
    moon test --target {{target}}

# Real Chromium DOM and configuration bridge integration tests
test-integration:
    cd test/integration && pnpm test

# Run tests (native)
test-native:
    moon test --target native

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean

# Pre-release check
release-check: fmt info check test
