#!/bin/bash
#
# TaaOS AI Assistant Setup
# Installs and configures a local LLM environment (Ollama)
#

echo "Setting up TaaOS AI Assistant..."

# 1. Install Ollama (Local LLM Runner)
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi

# 2. Enable Service
systemctl enable --now ollama

# 3. Pull Default Model (Mistral or Llama3 - optimized for speed)
echo "Downloading base model (this may take a while)..."
ollama pull llama3

# 4. Create TaaOS System Prompt
echo "Creating TaaOS Expert Model..."
cat <<EOF > Modelfile
FROM llama3
SYSTEM "You are TaaOS AI, an expert assistant for the TaaOS operating system. You are helpful, concise, and knowledgeable about Linux, Arch, and TaaOS specific tools like taapac and taaos-guardian."
EOF

ollama create taaos-expert -f Modelfile
rm Modelfile

# 5. Create CLI Wrapper
cat <<EOF > /usr/bin/taaos-ai
#!/bin/bash
echo "🤖 TaaOS AI Assistant"
echo "Type 'exit' to quit."
ollama run taaos-expert
EOF

chmod +x /usr/bin/taaos-ai

echo "✓ TaaOS AI Assistant ready! Run 'taaos-ai' to start."
