#!/bin/bash
#
# TaaOS Repository Builder
# Creates package repository structure
#

REPO_ROOT="/var/lib/taapac/repos"
REPO_NAME="taaos-core"

mkdir -p "$REPO_ROOT/$REPO_NAME"/{x86_64,sources}

# Create repository database
repo-add "$REPO_ROOT/$REPO_NAME/x86_64/$REPO_NAME.db.tar.gz"

# Sign repository
gpg --detach-sign --use-agent "$REPO_ROOT/$REPO_NAME/x86_64/$REPO_NAME.db.tar.gz"

echo "Repository created: $REPO_ROOT/$REPO_NAME"
