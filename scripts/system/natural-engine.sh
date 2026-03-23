#!/bin/bash
# =============================================================================
# TaaOS Natural Engine
# =============================================================================
# Context-aware AI assistant using Ollama for natural language commands
# =============================================================================

set -euo pipefail

# Configuration
OLLAMA_MODEL="${TAAOS_AI_MODEL:-phi}"
CONVERSATION_HISTORY="/tmp/natural-history-${USER:-root}.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =============================================================================
# SYSTEM CONTEXT
# =============================================================================
get_system_context() {
    local containers=0
    local disk_usage="N/A"
    
    # Get container count if docker is available
    if command -v docker &> /dev/null; then
        containers=$(docker ps -q 2>/dev/null | wc -l || echo 0)
    fi
    
    # Get disk usage
    disk_usage=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' || echo "N/A")
    
    cat << EOF
{
    "os": "$(uname -o 2>/dev/null || echo "Linux")",
    "kernel": "$(uname -r)",
    "user": "${USER:-root}",
    "cwd": "$PWD",
    "hostname": "$(hostname)",
    "running_containers": $containers,
    "disk_usage": "$disk_usage",
    "date": "$(date '+%Y-%m-%d %H:%M')"
}
EOF
}

# =============================================================================
# CONVERSATION HISTORY
# =============================================================================
save_conversation() {
    local user_input="$1"
    local ai_response="$2"
    
    if command -v jq &> /dev/null; then
        jq -n \
            --arg user "$user_input" \
            --arg assistant "$ai_response" \
            --arg timestamp "$(date -Iseconds)" \
            '{timestamp: $timestamp, user: $user, assistant: $assistant}' \
            >> "$CONVERSATION_HISTORY" 2>/dev/null || true
    fi
}

get_recent_history() {
    if [[ -f "$CONVERSATION_HISTORY" ]] && command -v jq &> /dev/null; then
        tail -5 "$CONVERSATION_HISTORY" 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

clear_history() {
    rm -f "$CONVERSATION_HISTORY"
    echo -e "${GREEN}✓${NC} Conversation history cleared"
}

# =============================================================================
# OLLAMA INTEGRATION
# =============================================================================
check_ollama() {
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}Error:${NC} Ollama is not installed"
        echo ""
        echo "Install Ollama:"
        echo "  curl -fsSL https://ollama.com/install.sh | sh"
        echo ""
        echo "Or use taaos-pkg:"
        echo "  taaos-pkg install ai-ml"
        return 1
    fi
    
    if ! pgrep -x "ollama" > /dev/null 2>&1; then
        echo -e "${YELLOW}Starting Ollama server...${NC}"
        ollama serve &>/dev/null &
        sleep 2
    fi
    
    return 0
}

ensure_model() {
    local model="$1"
    
    if ! ollama list 2>/dev/null | grep -q "$model"; then
        echo -e "${YELLOW}Downloading model: $model${NC}"
        ollama pull "$model"
    fi
}

# =============================================================================
# COMMAND MODE
# =============================================================================
natural_command() {
    local query="$*"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}Error:${NC} Please provide a query"
        echo "Usage: natural 'your question here'"
        return 1
    fi
    
    check_ollama || return 1
    ensure_model "$OLLAMA_MODEL"
    
    local context
    context=$(get_system_context)
    
    local prompt
    prompt=$(cat << EOF
You are a helpful Linux system assistant for TaaOS (Debian-based).
Convert the user's natural language request into a bash command.

System context:
$context

User request: $query

Rules:
1. Respond with ONLY the bash command, no explanation
2. If unclear, ask for clarification
3. For dangerous operations, add a safety warning
4. Use common Linux tools (apt, docker, git, etc.)

Response:
EOF
)
    
    echo -e "${CYAN}Thinking...${NC}"
    local response
    response=$(ollama run "$OLLAMA_MODEL" "$prompt" 2>/dev/null)
    
    echo ""
    echo -e "${GREEN}Suggested command:${NC}"
    echo -e "${MAGENTA}$response${NC}"
    echo ""
    
    read -p "Execute? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Executing...${NC}"
        eval "$response"
    fi
    
    save_conversation "$query" "$response"
}

# =============================================================================
# CHAT MODE
# =============================================================================
natural_chat() {
    check_ollama || return 1
    ensure_model "$OLLAMA_MODEL"
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Natural Engine Chat Mode                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Type ${YELLOW}exit${NC} to quit, ${YELLOW}clear${NC} to reset history"
    echo -e "Model: ${GREEN}$OLLAMA_MODEL${NC}"
    echo ""
    
    while true; do
        echo -ne "${GREEN}You:${NC} "
        read -r user_input
        
        [[ "$user_input" == "exit" ]] && break
        [[ "$user_input" == "clear" ]] && { clear_history; continue; }
        [[ -z "$user_input" ]] && continue
        
        local context
        context=$(get_system_context)
        
        local history
        history=$(get_recent_history)
        
        local prompt
        prompt=$(cat << EOF
You are a helpful Linux system assistant for TaaOS.

System context:
$context

Recent conversation:
$history

User: $user_input

Respond helpfully and concisely.
EOF
)
        
        echo -ne "${CYAN}AI:${NC} "
        ollama run "$OLLAMA_MODEL" "$prompt" 2>/dev/null
        echo ""
        
        save_conversation "$user_input" "(response saved)"
    done
    
    echo -e "${GREEN}Goodbye!${NC}"
}

# =============================================================================
# EXPLAIN MODE
# =============================================================================
natural_explain() {
    local command="$*"
    
    if [[ -z "$command" ]]; then
        echo -e "${RED}Error:${NC} Please provide a command to explain"
        echo "Usage: natural explain 'command here'"
        return 1
    fi
    
    check_ollama || return 1
    ensure_model "$OLLAMA_MODEL"
    
    local prompt
    prompt=$(cat << EOF
Explain this Linux command in simple terms:

$command

Include:
1. What it does
2. Each flag/option meaning
3. Example output
4. Any warnings

Be concise but thorough.
EOF
)
    
    echo -e "${CYAN}Explaining:${NC} $command"
    echo ""
    ollama run "$OLLAMA_MODEL" "$prompt" 2>/dev/null
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
show_help() {
    cat << 'EOF'
======================================================================
           TAAOS NATURAL ENGINE - AI COMMAND ASSISTANT                
======================================================================

USAGE:
  natural-engine <query>           Convert natural language to command
  natural-engine chat              Start interactive AI terminal chat
  natural-engine explain <cmd>     Explain a complex Linux command
  natural-engine --model <name>    Use specific Ollama model (e.g. llama2)

OPTIONS:
  --model, -m <name>    Changes the AI model for the current request.
                        If the model is not on your disk, TaaOS will
                        automatically download it for you.
  --chat, -c            Launch full-screen chat mode.
  --explain, -e         Provide a deep-dive explanation of a command.
  --clear               Clear your AI conversation history.
  --help, -h            Show this help text.

EXAMPLES:
  natural-engine "bana belleği en çok tüketen 5 programı göster"
  natural-engine chat
  natural-engine explain "find / -name '*.log' -type f -delete"
  natural-engine --model codellama "write a python script to ping google"

ENVIRONMENT:
  TAAOS_AI_MODEL        Set default model persistently (default: phi)

RECOMMENDED MODELS:
  phi                   Super fast, lightweight (Default)
  llama2                More capable, slower, needs more RAM
  codellama             Expert at writing code
======================================================================
EOF
}

main() {
    case "${1:-}" in
        chat|--chat|-c)
            natural_chat
            ;;
        explain|--explain|-e)
            shift
            natural_explain "$@"
            ;;
        --model|-m)
            OLLAMA_MODEL="${2:-phi}"
            shift 2
            natural_command "$@"
            ;;
        --help|-h|help)
            show_help
            ;;
        --clear)
            clear_history
            ;;
        "")
            show_help
            ;;
        *)
            natural_command "$@"
            ;;
    esac
}

main "$@"
