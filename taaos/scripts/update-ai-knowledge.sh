#!/bin/bash
#
# TaaOS AI RAG Setup
# Indexes TaaOS documentation for the AI model
#

echo "Indexing TaaOS Documentation for AI..."

DOCS_DIR="/usr/share/doc/taaos"
MODEL_FILE="/var/lib/taaos/ai/Modelfile.rag"

mkdir -p /var/lib/taaos/ai

# 1. Collect Documentation Content
echo "Reading documentation..."
ALL_DOCS=""
for f in $DOCS_DIR/*.md; do
    if [ -f "$f" ]; then
        CONTENT=$(cat "$f")
        ALL_DOCS+="\n\n--- FILE: $(basename $f) ---\n$CONTENT"
    fi
done

# 2. Create Enhanced Modelfile with Knowledge
echo "Creating Knowledge Base..."
cat <<EOF > "$MODEL_FILE"
FROM llama3
SYSTEM """
You are TaaOS AI, the intelligent assistant for the TaaOS operating system.
You have access to the following internal documentation about TaaOS:

$ALL_DOCS

Use this information to answer user questions accurately.
If asked about package management, refer to 'taapac'.
If asked about security, refer to 'taaos-guardian'.
If asked about system settings, refer to 'TaaOS Control Center'.
Always be concise, professional, and helpful.
"""
EOF

# 3. Update the Model
echo "Updating AI Model with RAG data..."
if command -v ollama &> /dev/null; then
    ollama create taaos-expert -f "$MODEL_FILE"
    echo "✓ AI Model updated with latest TaaOS knowledge."
else
    echo "⚠ Ollama not found. Skipping model update."
fi

rm "$MODEL_FILE"
