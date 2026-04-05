alias k="kubectl"
alias kz="kustomize"
alias kname-prd="k config set-context --current --namespace=cloud-prd"
alias kname-stg="k config set-context --current --namespace=cloud-stg"

alias oo="cd $HOME/Documents/obsidian_vault && nvim ."
alias or="nvim $HOME/Documents/obsidian_vault/inbox/*.md"
alias p="pnpm"
alias rd="rmdir"

alias tf=terraform

# SSH wrapper: tint terminal background while connected to a remote host
function ssh() {
  printf '\033]11;#382830\033\\'
  command ssh "$@"
  local ret=$?
  printf '\033]11;#303446\033\\'
  return $ret
}

# Dev shells -- enter from anywhere
alias shell-default="nix develop $HOME/Development/Personal/kaynix#default"
alias shell-python="nix develop $HOME/Development/Personal/kaynix#python"
alias shell-sketchy="nix develop $HOME/Development/Personal/kaynix#sketchybar"
