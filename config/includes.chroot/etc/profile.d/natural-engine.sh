# TaaOS Natural Engine (TaaNOS) Aliases
# Only load in interactive shells
[ -n "${BASH_VERSION:-}" -o -n "${ZSH_VERSION:-}" ] || return 0
case "$-" in *i*) ;; *) return 0 ;; esac

# Natural Engine shortcuts — all point to TaaNOS binary
alias natural='taanos'
alias n='taanos'
alias ai='taanos'
alias ask='taanos'

# Quick command shortcut
alias "?"='taanos'
