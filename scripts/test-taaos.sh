#!/bin/bash
#
# TaaOS Test Suite
# Comprehensive testing for all TaaOS components
#

set -e

TAAOS_ROOT="$(pwd)"
TEST_DIR="$TAAOS_ROOT/tests"
RESULTS_DIR="$TEST_DIR/results"

mkdir -p "$RESULTS_DIR"

echo "========================================="
echo "   TaaOS Test Suite"
echo "========================================="
echo ""

# Test 1: Kernel Module
echo "[1/10] Testing TaaOS Kernel Module..."
if lsmod | grep -q taaos_core; then
    echo "✓ Kernel module loaded"
    if [ -d /proc/taaos ]; then
        echo "✓ /proc/taaos interface exists"
        cat /proc/taaos/info > "$RESULTS_DIR/kernel-info.txt"
    else
        echo "✗ /proc/taaos interface missing"
    fi
else
    echo "✗ Kernel module not loaded"
fi

# Test 2: Neural Engine
echo "[2/10] Testing Neural Engine..."
if systemctl is-active --quiet taaos-neural-engine; then
    echo "✓ Neural Engine service running"
else
    echo "✗ Neural Engine service not running"
fi

# Test 3: TaaOS Brain
echo "[3/10] Testing TaaOS Brain..."
if systemctl is-active --quiet taaos-brain; then
    echo "✓ Brain service running"
else
    echo "✗ Brain service not running"
fi

# Test 4: AI Subsystem
echo "[4/10] Testing AI Subsystem..."
if command -v ollama &> /dev/null; then
    echo "✓ Ollama installed"
    if ollama list | grep -q taaos-expert; then
        echo "✓ TaaOS AI model present"
    else
        echo "✗ TaaOS AI model missing"
    fi
else
    echo "✗ Ollama not installed"
fi

# Test 5: Package Manager
echo "[5/10] Testing Package Manager..."
if command -v taapac &> /dev/null; then
    echo "✓ TaaPac installed"
else
    echo "✗ TaaPac not installed"
fi

# Test 6: Development Tools
echo "[6/10] Testing Development Tools..."
TOOLS=("docker" "git" "python3" "rustc" "node")
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "✓ $tool installed"
    else
        echo "✗ $tool not installed"
    fi
done

# Test 7: GUI Applications
echo "[7/10] Testing GUI Applications..."
GUI_APPS=("taaos-ai-gui" "taaos-monitor" "taaos-welcome")
for app in "${GUI_APPS[@]}"; do
    if command -v "$app" &> /dev/null; then
        echo "✓ $app installed"
    else
        echo "✗ $app not installed"
    fi
done

# Test 8: Security
echo "[8/10] Testing Security..."
if systemctl is-active --quiet ufw; then
    echo "✓ Firewall active"
else
    echo "✗ Firewall inactive"
fi

if systemctl is-active --quiet fail2ban; then
    echo "✓ Fail2Ban active"
else
    echo "✗ Fail2Ban inactive"
fi

# Test 9: Performance
echo "[9/10] Testing Performance..."
TIMER_FREQ=$(cat /proc/sys/kernel/sched_latency_ns)
echo "  Scheduler latency: $TIMER_FREQ ns"

IO_SCHEDULER=$(cat /sys/block/sda/queue/scheduler 2>/dev/null || echo "N/A")
echo "  I/O Scheduler: $IO_SCHEDULER"

# Test 10: Branding
echo "[10/10] Testing Branding..."
if [ -f /usr/share/wallpapers/taaos/taaos-default.png ]; then
    echo "✓ Wallpapers installed"
else
    echo "✗ Wallpapers missing"
fi

if [ -f /usr/share/plymouth/themes/taaos/taaos.plymouth ]; then
    echo "✓ Plymouth theme installed"
else
    echo "✗ Plymouth theme missing"
fi

echo ""
echo "========================================="
echo "   Test Suite Complete"
echo "========================================="
echo "Results saved to: $RESULTS_DIR"
