# Standalone kube context prompt helper
# Requires: autoload -Uz colors && colors (for $fg / $reset_color)
# Requires: kubectl in PATH

function kube_prompt_info() {
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null) || return
  echo "%{$fg[cyan]%}[${ctx:gs/%/%%}]%{$reset_color%} "
}
