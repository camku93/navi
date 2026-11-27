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

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Autosuggestions (must load BEFORE syntax-highlighting)
[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
	source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (must be sourced LAST)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
	source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

typeset -A ZSH_HIGHLIGHT_STYLES

navi_rgb() { printf '38;2;%d;%d;%d' 0x${1:1:2} 0x${1:3:2} 0x${1:5:2}; }

navi_theme_load() {
	local f="$HOME/.config/navi/theme"
	[[ -f $f/colors.sh ]] && . "$f/colors.sh"
	navi_theme_stamp=
	[[ -r $f/stamp ]] && navi_theme_stamp=$(<"$f/stamp")
	local text=${navi_text:-#e8eaf0} accent=${navi_accent:-#b8567f} cool=${navi_cool:-#5c6b8a}
	local dim=${navi_dim:-#8b9ab8} soft=${navi_soft:-#d9b3c0}
	PROMPT="%F{$accent}[%n@%m %1~]\$%f "
	ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${navi_hint:-#7a5261}"
	ZSH_HIGHLIGHT_STYLES[default]="fg=$text"
	ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=$accent,bold"
	ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=$cool"
	ZSH_HIGHLIGHT_STYLES[alias]="fg=$cool"
	ZSH_HIGHLIGHT_STYLES[builtin]="fg=$cool"
	ZSH_HIGHLIGHT_STYLES[function]="fg=$cool"
	ZSH_HIGHLIGHT_STYLES[command]="fg=$cool"
	ZSH_HIGHLIGHT_STYLES[precommand]="fg=$cool,underline"
	ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=$text"
	ZSH_HIGHLIGHT_STYLES[path]="fg=$text,underline"
	ZSH_HIGHLIGHT_STYLES[globbing]="fg=$accent"
	ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=$accent"
	ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=$accent"
	ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=$accent"
	ZSH_HIGHLIGHT_STYLES[comment]="fg=${navi_comment:-#2b3350}"
	local a=$(navi_rgb $accent) t=$(navi_rgb $text) c=$(navi_rgb $cool) d=$(navi_rgb $dim) s=$(navi_rgb $soft)
	export LS_COLORS="di=${a}:fi=${t}:ln=${c}:ex=${d}:*.jpg=${s}:*.png=${s}:*.mp3=${s}:*.mp4=${s}:*.txt=${t}:*.md=${t}"
}

navi_theme_check() {
	local f="$HOME/.config/navi/theme/stamp" s=
	[[ -r $f ]] && s=$(<"$f")
	[[ $s == "$navi_theme_stamp" ]] || navi_theme_load
}

navi_theme_load
autoload -Uz add-zsh-hook
add-zsh-hook precmd navi_theme_check

export GPG_TTY=$(tty)
