# ~/.zshrc
#

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

export EDITOR=vim
export VISUAL=vim
export TERMINAL=st
export PATH="$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias lf='lfv'
ncmpcpp() { if [ $# -eq 0 ]; then ncmpcppv; else command ncmpcpp "$@"; fi; }

# Prompt: [user@host cwd]$ in rose accent color
PROMPT='%F{#b8567f}[%n@%m %1~]$%f '

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Autosuggestions (must load BEFORE syntax-highlighting)
[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
	source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7a5261'

# Syntax highlighting (must be sourced LAST)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
	source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#e8eaf0'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#b8567f,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#5c6b8a'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#5c6b8a'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#5c6b8a'
ZSH_HIGHLIGHT_STYLES[function]='fg=#5c6b8a'
ZSH_HIGHLIGHT_STYLES[command]='fg=#5c6b8a'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#5c6b8a,underline'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#e8eaf0'
ZSH_HIGHLIGHT_STYLES[path]='fg=#e8eaf0,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#b8567f'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#b8567f'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#b8567f'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#b8567f'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#2b3350'

# LS_COLORS 
export LS_COLORS="di=38;2;184;86;127:fi=38;2;232;234;240:ln=38;2;92;107;138:ex=38;2;139;154;184:*.jpg=38;2;217;179;192:*.png=38;2;217;179;192:*.mp3=38;2;217;179;192:*.mp4=38;2;217;179;192:*.txt=38;2;232;234;240:*.md=38;2;232;234;240"
