# Minimal zsh history settings for fallback (Atuin handles primary history management)
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=10000
HISTSIZE=10000

# Basic history options
setopt HIST_IGNORE_SPACE         # Don't record entries starting with a space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
