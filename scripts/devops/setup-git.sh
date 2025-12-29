#!/bin/bash
# =============================================================================
# TaaOS Git Infrastructure Setup
# =============================================================================
# Script: setup-git.sh
# Purpose: Install Git ecosystem, GitHub CLI, and shell integrations
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS Git Infrastructure Setup"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: CORE GIT INSTALLATION
# -----------------------------------------------------------------------------
install_git_core() {
    echo "[GIT] Installing Git core components..."
    
    apt-get update
    
    # Install Git and essential tools
    apt-get install -y \
        git \
        git-lfs \
        git-doc \
        git-email \
        git-gui \
        gitk \
        curl \
        wget \
        gnupg
    
    # Verify installation
    echo "[GIT] Git version: $(git --version)"
    
    echo "[GIT] Core Git installation complete"
}

# -----------------------------------------------------------------------------
# SECTION 2: GIT LFS INITIALIZATION
# -----------------------------------------------------------------------------
setup_git_lfs() {
    echo "[GIT] Setting up Git Large File Storage..."
    
    # Initialize Git LFS globally
    git lfs install --system
    
    # Configure LFS settings
    git config --system lfs.batch true
    git config --system lfs.concurrenttransfers 8
    
    # Create global LFS attributes template
    mkdir -p /etc/skel/.config/git
    cat > /etc/skel/.config/git/attributes << 'LFS_ATTRS'
# TaaOS Git LFS Attributes
# Large binary files to track with LFS

# Images
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text
*.ico filter=lfs diff=lfs merge=lfs -text
*.svg filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text

# Audio
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text

# Video
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.avi filter=lfs diff=lfs merge=lfs -text
*.webm filter=lfs diff=lfs merge=lfs -text

# Archives
*.zip filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.rar filter=lfs diff=lfs merge=lfs -text
*.7z filter=lfs diff=lfs merge=lfs -text

# Compiled
*.exe filter=lfs diff=lfs merge=lfs -text
*.dll filter=lfs diff=lfs merge=lfs -text
*.so filter=lfs diff=lfs merge=lfs -text
*.dylib filter=lfs diff=lfs merge=lfs -text

# Data files
*.sqlite filter=lfs diff=lfs merge=lfs -text
*.db filter=lfs diff=lfs merge=lfs -text

# Fonts
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text
*.woff filter=lfs diff=lfs merge=lfs -text
*.woff2 filter=lfs diff=lfs merge=lfs -text
LFS_ATTRS

    echo "[GIT] Git LFS configured"
}

# -----------------------------------------------------------------------------
# SECTION 3: GITHUB CLI INSTALLATION
# -----------------------------------------------------------------------------
install_github_cli() {
    echo "[GIT] Installing GitHub CLI..."
    
    # Create keyrings directory
    mkdir -p /etc/apt/keyrings
    
    # Add GitHub CLI GPG key
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
    
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    
    # Add GitHub CLI repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    # Update and install
    apt-get update
    apt-get install -y gh
    
    # Verify installation
    echo "[GIT] GitHub CLI version: $(gh --version | head -1)"
    
    # Create completion script
    gh completion -s bash > /etc/bash_completion.d/gh 2>/dev/null || true
    
    echo "[GIT] GitHub CLI installed"
}

# -----------------------------------------------------------------------------
# SECTION 4: SHELL INTEGRATION - GIT BRANCH IN PS1
# -----------------------------------------------------------------------------
setup_shell_integration() {
    echo "[GIT] Configuring shell integration..."
    
    # Add Git branch function and PS1 to system bashrc
    cat >> /etc/bash.bashrc << 'GIT_SHELL_INTEGRATION'

# =============================================================================
# TaaOS Git Shell Integration
# =============================================================================
# Displays current Git branch in terminal prompt with color coding
# =============================================================================

# Git branch detection function
__taaos_git_branch() {
    local branch
    if branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        echo "$branch"
    elif branch=$(git describe --tags --exact-match 2>/dev/null); then
        echo "tag:$branch"
    elif branch=$(git rev-parse --short HEAD 2>/dev/null); then
        echo "detached:$branch"
    fi
}

# Git status indicators
__taaos_git_status() {
    local status=""
    local git_status
    
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        return
    fi
    
    git_status=$(git status --porcelain 2>/dev/null)
    
    # Check for uncommitted changes
    if [[ -n "$git_status" ]]; then
        status+="*"
    fi
    
    # Check for unpushed commits
    if git log --oneline @{upstream}.. 2>/dev/null | grep -q .; then
        status+="↑"
    fi
    
    # Check for unpulled commits
    if git log --oneline ..@{upstream} 2>/dev/null | grep -q .; then
        status+="↓"
    fi
    
    echo "$status"
}

# Complete Git prompt component
__taaos_git_prompt() {
    local branch=$(__taaos_git_branch)
    
    if [[ -n "$branch" ]]; then
        local status=$(__taaos_git_status)
        local color
        
        # Color coding based on status
        if [[ -n "$status" ]]; then
            color="\[\033[1;33m\]"  # Yellow for dirty
        else
            color="\[\033[1;32m\]"  # Green for clean
        fi
        
        echo "${color}(${branch}${status})\[\033[0m\] "
    fi
}

# Only set PS1 for interactive shells
if [[ $- == *i* ]]; then
    # TaaOS Custom Prompt
    # Format: [user@host:path] (branch*) $
    
    # Colors
    TAAOS_CYAN='\[\033[0;36m\]'
    TAAOS_BLUE='\[\033[0;34m\]'
    TAAOS_GREEN='\[\033[0;32m\]'
    TAAOS_YELLOW='\[\033[1;33m\]'
    TAAOS_RED='\[\033[0;31m\]'
    TAAOS_WHITE='\[\033[1;37m\]'
    TAAOS_RESET='\[\033[0m\]'
    
    # Build PS1 with Git integration
    __taaos_set_prompt() {
        local exit_code=$?
        local git_info=$(__taaos_git_prompt)
        
        # User color (red for root, cyan for normal)
        local user_color
        if [[ $EUID -eq 0 ]]; then
            user_color="${TAAOS_RED}"
        else
            user_color="${TAAOS_CYAN}"
        fi
        
        # Exit code indicator
        local exit_indicator
        if [[ $exit_code -eq 0 ]]; then
            exit_indicator="${TAAOS_GREEN}✓${TAAOS_RESET}"
        else
            exit_indicator="${TAAOS_RED}✗${TAAOS_RESET}"
        fi
        
        # Shortened path (max 3 directories)
        local short_path
        short_path=$(pwd | sed "s|^$HOME|~|" | awk -F'/' '{
            if (NF > 4) {
                print $(NF-2)"/"$(NF-1)"/"$NF
            } else {
                print $0
            }
        }')
        
        PS1="${exit_indicator} ${user_color}\u${TAAOS_RESET}@${TAAOS_BLUE}\h${TAAOS_RESET}:${TAAOS_WHITE}${short_path}${TAAOS_RESET} ${git_info}\$ "
    }
    
    PROMPT_COMMAND="__taaos_set_prompt"
fi
GIT_SHELL_INTEGRATION

    # Also add to skel for new users
    cat >> /etc/skel/.bashrc << 'SKEL_GIT'

# Git prompt is configured system-wide in /etc/bash.bashrc
# Custom git aliases
alias gs='git status'
alias gl='git log --oneline -20'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gm='git merge'
alias gst='git stash'
alias gf='git fetch --all --prune'
alias glg='git log --graph --oneline --decorate --all'
SKEL_GIT

    echo "[GIT] Shell integration configured"
}

# -----------------------------------------------------------------------------
# SECTION 5: GIT SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
configure_git_system() {
    echo "[GIT] Configuring Git system settings..."
    
    # Safe directory for shared environments (prevents ownership errors)
    git config --system --add safe.directory '*'
    
    # Default branch name
    git config --system init.defaultBranch main
    
    # Useful defaults
    git config --system core.autocrlf input
    git config --system core.safecrlf warn
    git config --system core.editor nano
    git config --system color.ui auto
    git config --system push.default current
    git config --system pull.rebase false
    git config --system fetch.prune true
    git config --system diff.colorMoved zebra
    git config --system merge.conflictstyle diff3
    git config --system rebase.autoStash true
    
    # Better diff algorithm
    git config --system diff.algorithm histogram
    
    # Commit template
    mkdir -p /etc/skel/.config/git
    cat > /etc/skel/.config/git/commit-template << 'COMMIT_TEMPLATE'

# Title: Brief description (50 chars max)
# 
# Body: Detailed explanation (wrap at 72 chars)
# - What changed
# - Why it changed
# - Any side effects
#
# Footer: Issue references, breaking changes
# Fixes #123
# BREAKING CHANGE: description
COMMIT_TEMPLATE

    git config --system commit.template ~/.config/git/commit-template
    
    # Ignore common files globally
    cat > /etc/skel/.config/git/ignore << 'GLOBAL_IGNORE'
# TaaOS Global Git Ignore

# OS files
.DS_Store
Thumbs.db
desktop.ini

# IDE files
.idea/
.vscode/
*.swp
*.swo
*~
.project
.classpath
.settings/

# Build outputs
*.log
*.tmp
*.temp
*.cache

# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc

# Environment
.env
.env.local
*.local

# Compiled
*.o
*.a
*.so
*.dll
*.exe
*.out
GLOBAL_IGNORE

    git config --system core.excludesFile ~/.config/git/ignore
    
    echo "[GIT] System configuration applied"
}

# -----------------------------------------------------------------------------
# SECTION 6: ADDITIONAL GIT TOOLS
# -----------------------------------------------------------------------------
install_git_tools() {
    echo "[GIT] Installing additional Git tools..."
    
    # Tig - Text-mode interface for Git
    apt-get install -y tig || echo "[GIT] tig installation skipped"
    
    # Delta - Better git diff (if available)
    if curl -sL https://api.github.com/repos/dandavison/delta/releases/latest 2>/dev/null | grep -q "tag_name"; then
        DELTA_VERSION=$(curl -sL https://api.github.com/repos/dandavison/delta/releases/latest | grep -oP '"tag_name": "\K[^"]+')
        curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION#v}_amd64.deb" 2>/dev/null && \
            dpkg -i /tmp/delta.deb 2>/dev/null && \
            git config --system core.pager delta && \
            git config --system interactive.diffFilter "delta --color-only" && \
            git config --system delta.navigate true && \
            git config --system delta.light false || echo "[GIT] Delta installation skipped"
        rm -f /tmp/delta.deb
    fi
    
    # Git-crypt for encrypted files
    apt-get install -y git-crypt 2>/dev/null || echo "[GIT] git-crypt installation skipped"
    
    # Git-secret (if available)
    apt-get install -y git-secret 2>/dev/null || echo "[GIT] git-secret installation skipped"
    
    echo "[GIT] Additional tools installed"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[GIT] Starting Git Infrastructure Setup..."
    echo ""

    install_git_core
    echo ""
    
    setup_git_lfs
    echo ""
    
    install_github_cli
    echo ""
    
    setup_shell_integration
    echo ""
    
    configure_git_system
    echo ""
    
    install_git_tools
    echo ""

    echo "=============================================="
    echo "  Git Infrastructure Setup - COMPLETE!"
    echo "=============================================="
    echo ""
    echo "  Installed Components:"
    echo "  - Git $(git --version | cut -d' ' -f3)"
    echo "  - Git LFS (configured globally)"
    echo "  - GitHub CLI (gh)"
    echo "  - Shell integration (branch in PS1)"
    echo "  - Tig, Delta (enhanced diff)"
    echo ""
    echo "  Features:"
    echo "  - Branch name in prompt with status"
    echo "  - Safe directory configured"
    echo "  - Global ignore and commit template"
    echo "  - Git aliases (gs, gl, gd, etc.)"
    echo ""
}

# Run main function
main "$@"
