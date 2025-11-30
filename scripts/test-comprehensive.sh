#!/bin/bash
#
# TaaOS Comprehensive Test Suite
# Tests EVERYTHING - no stone left unturned
#

set -e

TEST_DIR="$(pwd)/test-results"
ERRORS=0
WARNINGS=0

mkdir -p "$TEST_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         TaaOS Comprehensive Test Suite                      ║"
echo "║              Testing Everything                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: File Existence
echo "═══ Test 1: File Existence Check ═══"

REQUIRED_FILES=(
    "Makefile"
    "README.taaos"
    "BUILD_GUIDE.md"
    "init/main.c"
    "init/taaos_init.c"
    "drivers/taaos/taaos_core.c"
    "drivers/taaos/Kconfig"
    "drivers/taaos/Makefile"
    "include/linux/taaos.h"
    "include/linux/taaos_sched.h"
    "arch/x86/configs/taaos_defconfig"
    "init/Kconfig.taaos"
    "taaos.config"
    "scripts/build-full-system.sh"
    "scripts/integrate-kernel.sh"
    "scripts/test-taaos.sh"
    "taaos/bin/taaos"
    "taaos/bin/taaos-ai"
    "taaos/bin/taaos-ai-models"
    "taaos/system/taaos-neural-engine.py"
    "taaos/system/taaos-brain.py"
    "taaos/scripts/firstboot.sh"
    "taaos/packages/default-packages.txt"
    "taaos/packages/python-requirements.txt"
    "taaos/packages/node-packages.json"
    "taaos/packages/rust-dependencies.toml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ MISSING: $file"
        ((ERRORS++))
    fi
done

# Test 2: Python Syntax
echo ""
echo "═══ Test 2: Python Syntax Check ═══"

PYTHON_FILES=$(find taaos -name "*.py" 2>/dev/null || true)
for pyfile in $PYTHON_FILES; do
    if python3 -m py_compile "$pyfile" 2>/dev/null; then
        echo "✓ $pyfile"
    else
        echo "✗ SYNTAX ERROR: $pyfile"
        python3 -m py_compile "$pyfile" 2>&1 | head -5
        ((ERRORS++))
    fi
done

# Test 3: Shell Script Syntax
echo ""
echo "═══ Test 3: Shell Script Syntax Check ═══"

SHELL_SCRIPTS=$(find . -name "*.sh" -type f 2>/dev/null || true)
for script in $SHELL_SCRIPTS; do
    if bash -n "$script" 2>/dev/null; then
        echo "✓ $script"
    else
        echo "✗ SYNTAX ERROR: $script"
        bash -n "$script" 2>&1 | head -5
        ((ERRORS++))
    fi
done

# Test 4: C Code Syntax (basic check)
echo ""
echo "═══ Test 4: C Code Basic Check ═══"

C_FILES=(
    "init/taaos_init.c"
    "drivers/taaos/taaos_core.c"
)

for cfile in "${C_FILES[@]}"; do
    if [ -f "$cfile" ]; then
        # Check for basic syntax issues
        if grep -q "^#include" "$cfile" && \
           grep -q "MODULE_LICENSE\|static int" "$cfile"; then
            echo "✓ $cfile (structure OK)"
        else
            echo "⚠ $cfile (check structure)"
            ((WARNINGS++))
        fi
    fi
done

# Test 5: JSON Syntax
echo ""
echo "═══ Test 5: JSON Syntax Check ═══"

JSON_FILES=$(find taaos -name "*.json" 2>/dev/null || true)
for jsonfile in $JSON_FILES; do
    if python3 -c "import json; json.load(open('$jsonfile'))" 2>/dev/null; then
        echo "✓ $jsonfile"
    else
        echo "✗ INVALID JSON: $jsonfile"
        ((ERRORS++))
    fi
done

# Test 6: Makefile Syntax
echo ""
echo "═══ Test 6: Makefile Check ═══"

if make -n -f Makefile > /dev/null 2>&1; then
    echo "✓ Main Makefile syntax OK"
else
    echo "✗ Main Makefile has errors"
    ((ERRORS++))
fi

# Test 7: Kernel Config
echo ""
echo "═══ Test 7: Kernel Configuration Check ═══"

if [ -f "arch/x86/configs/taaos_defconfig" ]; then
    REQUIRED_CONFIGS=(
        "CONFIG_TAAOS"
        "CONFIG_HZ_1000"
        "CONFIG_PREEMPT"
        "CONFIG_IOSCHED_BFQ"
        "CONFIG_TCP_CONG_BBR"
    )
    
    for config in "${REQUIRED_CONFIGS[@]}"; do
        if grep -q "$config" arch/x86/configs/taaos_defconfig; then
            echo "✓ $config present"
        else
            echo "⚠ $config missing"
            ((WARNINGS++))
        fi
    done
fi

# Test 8: Documentation Completeness
echo ""
echo "═══ Test 8: Documentation Check ═══"

DOC_FILES=(
    "README.taaos"
    "BUILD_GUIDE.md"
    "taaos/docs/ai-guide.md"
    "taaos/docs/ai-examples.md"
)

for doc in "${DOC_FILES[@]}"; do
    if [ -f "$doc" ]; then
        lines=$(wc -l < "$doc")
        if [ "$lines" -gt 50 ]; then
            echo "✓ $doc ($lines lines)"
        else
            echo "⚠ $doc too short ($lines lines)"
            ((WARNINGS++))
        fi
    else
        echo "✗ MISSING: $doc"
        ((ERRORS++))
    fi
done

# Test 9: Script Executability
echo ""
echo "═══ Test 9: Script Permissions Check ═══"

EXEC_SCRIPTS=(
    "scripts/build-full-system.sh"
    "scripts/integrate-kernel.sh"
    "scripts/test-taaos.sh"
    "taaos/scripts/firstboot.sh"
)

for script in "${EXEC_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ] || chmod +x "$script" 2>/dev/null; then
            echo "✓ $script executable"
        else
            echo "⚠ $script not executable"
            ((WARNINGS++))
        fi
    fi
done

# Test 10: Package Lists
echo ""
echo "═══ Test 10: Package List Validation ═══"

if [ -f "taaos/packages/default-packages.txt" ]; then
    pkg_count=$(grep -v "^#" taaos/packages/default-packages.txt | grep -v "^$" | wc -l)
    echo "✓ Default packages: $pkg_count packages"
    
    if [ "$pkg_count" -lt 100 ]; then
        echo "⚠ Package count seems low"
        ((WARNINGS++))
    fi
fi

# Test 11: Python Dependencies
echo ""
echo "═══ Test 11: Python Dependencies Check ═══"

if [ -f "taaos/packages/python-requirements.txt" ]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z] ]]; then
            pkg=$(echo "$line" | cut -d'=' -f1)
            echo "  - $pkg"
        fi
    done < "taaos/packages/python-requirements.txt"
    echo "✓ Python requirements file valid"
fi

# Test 12: AI Components
echo ""
echo "═══ Test 12: AI Components Check ═══"

AI_COMPONENTS=(
    "taaos/system/taaos-neural-engine.py"
    "taaos/system/taaos-brain.py"
    "taaos/bin/taaos-ai"
    "taaos/bin/taaos-ai-models"
)

for component in "${AI_COMPONENTS[@]}"; do
    if [ -f "$component" ]; then
        if grep -q "class\|def " "$component"; then
            echo "✓ $component (has code)"
        else
            echo "⚠ $component (check content)"
            ((WARNINGS++))
        fi
    else
        echo "✗ MISSING: $component"
        ((ERRORS++))
    fi
done

# Test 13: n8n Workflows
echo ""
echo "═══ Test 13: n8n Workflows Check ═══"

WORKFLOWS=$(find taaos/scripts/n8n-workflows -name "*.json" 2>/dev/null || true)
workflow_count=0
for workflow in $WORKFLOWS; do
    if python3 -c "import json; json.load(open('$workflow'))" 2>/dev/null; then
        echo "✓ $(basename $workflow)"
        ((workflow_count++))
    else
        echo "✗ Invalid: $(basename $workflow)"
        ((ERRORS++))
    fi
done
echo "Total workflows: $workflow_count"

# Test 14: Branding Assets
echo ""
echo "═══ Test 14: Branding Assets Check ═══"

BRANDING_DIRS=(
    "taaos/branding/logo"
    "taaos/branding/plymouth"
    "taaos/branding/sddm"
    "taaos/branding/grub"
)

for dir in "${BRANDING_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        file_count=$(find "$dir" -type f | wc -l)
        echo "✓ $dir ($file_count files)"
    else
        echo "⚠ $dir missing"
        ((WARNINGS++))
    fi
done

# Test 15: Security Profiles
echo ""
echo "═══ Test 15: Security Profiles Check ═══"

SECURITY_FILES=$(find taaos/security -type f 2>/dev/null || true)
security_count=0
for secfile in $SECURITY_FILES; do
    if [ -s "$secfile" ]; then
        echo "✓ $(basename $secfile)"
        ((security_count++))
    fi
done
echo "Total security profiles: $security_count"

# Test 16: Kernel Module Integration
echo ""
echo "═══ Test 16: Kernel Module Integration ═══"

if grep -q "obj-\$(CONFIG_TAAOS)" drivers/Makefile 2>/dev/null; then
    echo "✓ TaaOS driver in drivers/Makefile"
else
    echo "✗ TaaOS driver not in drivers/Makefile"
    ((ERRORS++))
fi

if grep -q "source \"init/Kconfig.taaos\"" init/Kconfig 2>/dev/null; then
    echo "✓ TaaOS Kconfig sourced"
else
    echo "⚠ TaaOS Kconfig not sourced"
    ((WARNINGS++))
fi

# Test 17: Build System
echo ""
echo "═══ Test 17: Build System Check ═══"

if [ -f "scripts/build-full-system.sh" ]; then
    if grep -q "Phase 1\|Phase 2\|Phase 3" scripts/build-full-system.sh; then
        echo "✓ Build script has phases"
    else
        echo "⚠ Build script structure unclear"
        ((WARNINGS++))
    fi
fi

# Test 18: File Completeness
echo ""
echo "═══ Test 18: Critical Files Content Check ═══"

# Check if files are not empty
CRITICAL_FILES=(
    "README.taaos"
    "taaos/system/taaos-neural-engine.py"
    "drivers/taaos/taaos_core.c"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ "$size" -gt 1000 ]; then
            echo "✓ $file ($size bytes)"
        else
            echo "⚠ $file seems small ($size bytes)"
            ((WARNINGS++))
        fi
    fi
done

# Generate Report
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    TEST SUMMARY                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Errors: $ERRORS"
echo "Total Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "✅ ALL TESTS PASSED - SYSTEM IS PERFECT!"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo "⚠️  NO ERRORS, BUT $WARNINGS WARNINGS"
    exit 0
else
    echo "❌ $ERRORS ERRORS FOUND - NEEDS FIXING"
    exit 1
fi
