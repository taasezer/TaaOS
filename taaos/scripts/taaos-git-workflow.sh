#!/bin/bash
#
# TaaOS Git Workflow Manager
# Simplified Git operations with best practices
#

set -e

BRANCH_PREFIX="feature/"
COMMIT_TYPES=("feat" "fix" "docs" "style" "refactor" "test" "chore")

show_menu() {
    clear
    echo "========================================="
    echo "   TaaOS Git Workflow Manager"
    echo "========================================="
    echo ""
    echo "Current branch: $(git branch --show-current)"
    echo "Status: $(git status --short | wc -l) changes"
    echo ""
    echo "1. Start New Feature"
    echo "2. Commit Changes (Conventional)"
    echo "3. Push to Remote"
    echo "4. Create Pull Request"
    echo "5. Sync with Main"
    echo "6. View History"
    echo "7. Undo Last Commit"
    echo "8. Stash Changes"
    echo "9. Apply Stash"
    echo "0. Exit"
    echo ""
    read -p "Select option: " choice
}

start_feature() {
    read -p "Feature name (e.g., user-authentication): " feature_name
    branch_name="${BRANCH_PREFIX}${feature_name}"
    
    git checkout -b "$branch_name"
    echo "Created and switched to branch: $branch_name"
}

conventional_commit() {
    echo "Commit Types:"
    for i in "${!COMMIT_TYPES[@]}"; do
        echo "  $((i+1)). ${COMMIT_TYPES[$i]}"
    done
    
    read -p "Select type: " type_choice
    type_index=$((type_choice - 1))
    
    if [ $type_index -ge 0 ] && [ $type_index -lt ${#COMMIT_TYPES[@]} ]; then
        commit_type="${COMMIT_TYPES[$type_index]}"
        
        read -p "Scope (optional, e.g., auth, api): " scope
        read -p "Short description: " description
        read -p "Breaking change? (y/n): " breaking
        
        # Build commit message
        if [ -n "$scope" ]; then
            commit_msg="${commit_type}(${scope}): ${description}"
        else
            commit_msg="${commit_type}: ${description}"
        fi
        
        if [ "$breaking" = "y" ]; then
            commit_msg="${commit_msg}\n\nBREAKING CHANGE: "
            read -p "Describe breaking change: " breaking_desc
            commit_msg="${commit_msg}${breaking_desc}"
        fi
        
        # Stage and commit
        git add .
        echo -e "$commit_msg" | git commit -F -
        
        echo "Committed: $commit_msg"
    else
        echo "Invalid type selection"
    fi
}

push_to_remote() {
    current_branch=$(git branch --show-current)
    
    # Check if remote branch exists
    if git ls-remote --heads origin "$current_branch" | grep -q "$current_branch"; then
        git push
    else
        git push -u origin "$current_branch"
    fi
    
    echo "Pushed to origin/$current_branch"
}

create_pr() {
    current_branch=$(git branch --show-current)
    
    if command -v gh &> /dev/null; then
        gh pr create --base main --head "$current_branch"
    else
        echo "GitHub CLI not installed. Install with: taapac install github-cli"
        echo "Or create PR manually at your repository's GitHub page"
    fi
}

sync_with_main() {
    current_branch=$(git branch --show-current)
    
    git fetch origin
    git checkout main
    git pull origin main
    git checkout "$current_branch"
    git rebase main
    
    echo "Synced $current_branch with main"
}

view_history() {
    git log --oneline --graph --decorate --all -20
    echo ""
    read -p "Press Enter to continue..."
}

undo_last_commit() {
    read -p "Keep changes in working directory? (y/n): " keep_changes
    
    if [ "$keep_changes" = "y" ]; then
        git reset --soft HEAD~1
        echo "Commit undone, changes kept"
    else
        git reset --hard HEAD~1
        echo "Commit undone, changes discarded"
    fi
}

stash_changes() {
    read -p "Stash message: " stash_msg
    git stash push -m "$stash_msg"
    echo "Changes stashed"
}

apply_stash() {
    echo "Available stashes:"
    git stash list
    echo ""
    read -p "Stash index to apply (0 for latest): " stash_index
    
    git stash apply "stash@{$stash_index}"
    echo "Stash applied"
}

# Main loop
while true; do
    show_menu
    
    case $choice in
        1) start_feature ;;
        2) conventional_commit ;;
        3) push_to_remote ;;
        4) create_pr ;;
        5) sync_with_main ;;
        6) view_history ;;
        7) undo_last_commit ;;
        8) stash_changes ;;
        9) apply_stash ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
