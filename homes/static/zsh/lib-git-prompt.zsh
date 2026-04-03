# Standalone git prompt helpers (replaces oh-my-zsh lib/git.zsh)
# Requires: autoload -Uz colors && colors (for $fg / $reset_color)

function __git_prompt_git() {
  GIT_OPTIONAL_LOCKS=0 command git "$@"
}

function git_prompt_info() {
  __git_prompt_git rev-parse --git-dir &>/dev/null || return 0

  local ref
  ref=$(__git_prompt_git symbolic-ref --short HEAD 2>/dev/null) \
    || ref=$(__git_prompt_git describe --tags --exact-match HEAD 2>/dev/null) \
    || ref=$(__git_prompt_git rev-parse --short HEAD 2>/dev/null) \
    || return 0

  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref:gs/%/%%}$(parse_git_dirty)${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

function parse_git_dirty() {
  local STATUS
  local -a FLAGS
  FLAGS=('--porcelain' '--untracked-files=no')

  STATUS=$(__git_prompt_git status ${FLAGS} 2>/dev/null | tail -n 1)

  if [[ -n $STATUS ]]; then
    echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
  else
    echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi
}
