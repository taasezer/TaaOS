#!/bin/bash
#
# TaaOS Code Quality Analyzer
# Automated code quality checks and linting
#

PROJECT_DIR="${1:-.}"
REPORT_FILE="/tmp/taaos-code-quality-report.txt"

echo "TaaOS Code Quality Analyzer" > "$REPORT_FILE"
echo "===========================" >> "$REPORT_FILE"
echo "Project: $PROJECT_DIR" >> "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Detect project type
detect_project_type() {
    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo "node"
    elif [ -f "$PROJECT_DIR/Cargo.toml" ]; then
        echo "rust"
    elif [ -f "$PROJECT_DIR/setup.py" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
        echo "python"
    elif [ -f "$PROJECT_DIR/go.mod" ]; then
        echo "go"
    else
        echo "unknown"
    fi
}

# Python analysis
analyze_python() {
    echo "=== Python Code Analysis ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Flake8
    if command -v flake8 &> /dev/null; then
        echo "Running flake8..." >> "$REPORT_FILE"
        flake8 "$PROJECT_DIR" --count --statistics >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # Pylint
    if command -v pylint &> /dev/null; then
        echo "Running pylint..." >> "$REPORT_FILE"
        pylint "$PROJECT_DIR" --output-format=text >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # Black (formatting check)
    if command -v black &> /dev/null; then
        echo "Checking code formatting (black)..." >> "$REPORT_FILE"
        black --check "$PROJECT_DIR" >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # mypy (type checking)
    if command -v mypy &> /dev/null; then
        echo "Running type checker (mypy)..." >> "$REPORT_FILE"
        mypy "$PROJECT_DIR" >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # Safety (security vulnerabilities)
    if command -v safety &> /dev/null; then
        echo "Checking for security vulnerabilities..." >> "$REPORT_FILE"
        safety check >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
}

# Node.js analysis
analyze_node() {
    echo "=== Node.js Code Analysis ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    cd "$PROJECT_DIR" || exit
    
    # ESLint
    if [ -f "node_modules/.bin/eslint" ]; then
        echo "Running ESLint..." >> "$REPORT_FILE"
        npx eslint . >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # Prettier
    if [ -f "node_modules/.bin/prettier" ]; then
        echo "Checking code formatting (Prettier)..." >> "$REPORT_FILE"
        npx prettier --check . >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # npm audit
    echo "Running npm audit..." >> "$REPORT_FILE"
    npm audit >> "$REPORT_FILE" 2>&1
    echo "" >> "$REPORT_FILE"
}

# Rust analysis
analyze_rust() {
    echo "=== Rust Code Analysis ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    cd "$PROJECT_DIR" || exit
    
    # Clippy
    echo "Running Clippy..." >> "$REPORT_FILE"
    cargo clippy -- -D warnings >> "$REPORT_FILE" 2>&1
    echo "" >> "$REPORT_FILE"
    
    # Rustfmt
    echo "Checking code formatting (rustfmt)..." >> "$REPORT_FILE"
    cargo fmt -- --check >> "$REPORT_FILE" 2>&1
    echo "" >> "$REPORT_FILE"
    
    # Cargo audit
    if command -v cargo-audit &> /dev/null; then
        echo "Running cargo audit..." >> "$REPORT_FILE"
        cargo audit >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
}

# Go analysis
analyze_go() {
    echo "=== Go Code Analysis ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    cd "$PROJECT_DIR" || exit
    
    # go vet
    echo "Running go vet..." >> "$REPORT_FILE"
    go vet ./... >> "$REPORT_FILE" 2>&1
    echo "" >> "$REPORT_FILE"
    
    # golint
    if command -v golint &> /dev/null; then
        echo "Running golint..." >> "$REPORT_FILE"
        golint ./... >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    # gofmt
    echo "Checking code formatting (gofmt)..." >> "$REPORT_FILE"
    gofmt -l . >> "$REPORT_FILE" 2>&1
    echo "" >> "$REPORT_FILE"
}

# General metrics
calculate_metrics() {
    echo "=== Code Metrics ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Lines of code
    echo "Lines of Code:" >> "$REPORT_FILE"
    find "$PROJECT_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.rs" -o -name "*.go" \) | xargs wc -l | tail -1 >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # File count
    echo "File Count:" >> "$REPORT_FILE"
    find "$PROJECT_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.rs" -o -name "*.go" \) | wc -l >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Main execution
PROJECT_TYPE=$(detect_project_type)

echo "Detected project type: $PROJECT_TYPE"
echo "Project Type: $PROJECT_TYPE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

case $PROJECT_TYPE in
    python)
        analyze_python
        ;;
    node)
        analyze_node
        ;;
    rust)
        analyze_rust
        ;;
    go)
        analyze_go
        ;;
    *)
        echo "Unknown project type. Skipping language-specific analysis." >> "$REPORT_FILE"
        ;;
esac

calculate_metrics

echo "" >> "$REPORT_FILE"
echo "=== Analysis Complete ===" >> "$REPORT_FILE"

# Display report
cat "$REPORT_FILE"

echo ""
echo "Full report saved to: $REPORT_FILE"
