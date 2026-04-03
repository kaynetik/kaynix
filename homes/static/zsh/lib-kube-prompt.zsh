# Standalone kube context prompt helper
# Requires: autoload -Uz colors && colors (for $fg / $reset_color)
# Requires: kubectl in PATH
#
# KUBE_CTX_ALIASES is populated by the sops-decrypted file
# conf-kube-ctx-aliases.zsh (sourced from initContent before this file).
# If that file is missing (e.g. no YubiKey), the map stays empty and
# the prompt falls back to showing the raw context name.

typeset -gA KUBE_CTX_ALIASES

function kube_prompt_info() {
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null) || return
  local display="${KUBE_CTX_ALIASES[$ctx]:-$ctx}"
  echo "%{$fg[cyan]%}[${display:gs/%/%%}]%{$reset_color%} "
}

function kctx() {
  if [[ -z "$1" ]]; then
    kubectl config get-contexts
    return
  fi
  local target=""
  for full_name alias_name in "${(@kv)KUBE_CTX_ALIASES}"; do
    if [[ "$alias_name" == "$1" ]]; then
      target="$full_name"
      break
    fi
  done
  kubectl config use-context "${target:-$1}"
}
