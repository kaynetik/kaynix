# Standalone bira-style prompt (no Oh My Zsh dependency)
# Depends on: lib-git-prompt.zsh, lib-kube-prompt.zsh
# Requires: autoload -Uz colors && colors  +  setopt prompt_subst

function virtualenv_prompt_info() {
  [[ -n ${VIRTUAL_ENV} ]] || return
  echo "%{$fg[green]%}<${VIRTUAL_ENV:t:gs/%/%%}>%{$reset_color%} "
}
export VIRTUAL_ENV_DISABLE_PROMPT=1

local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"
local user_host="%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%} "
local user_symbol='%(!.#.$)'
local current_dir="%B%{$fg[blue]%}%~ %{$reset_color%}"

local vcs_branch='$(git_prompt_info)'
local venv_prompt='$(virtualenv_prompt_info)'
local kube_prompt='$(kube_prompt_info)'

PROMPT="╭─${user_host}${current_dir}${vcs_branch}${venv_prompt}${kube_prompt}
╰─%B${user_symbol}%b "
RPROMPT="%B${return_code}%b"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}<"
ZSH_THEME_GIT_PROMPT_SUFFIX=">%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[yellow]%}"
