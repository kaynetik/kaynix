alias eld="eza -lD --icons=auto"
alias elf="eza -lf --color=always --icons=auto | grep -v /"
alias elh="eza -dl .* --group-directories-first --icons=always"
alias ell="eza -al --group-directories-first --icons=always"
alias els="eza -alf --color=always --sort=size --icons=always | grep -v /"
alias elt="eza -al --sort=modified --icons=auto"

alias k="kubectl"
alias kz="kustomize"
alias kname-prd="k config set-context --current --namespace=cloud-prd"
alias kname-stg="k config set-context --current --namespace=cloud-stg"

alias oo="cd $HOME/Documents/obsidian_vault && nvim ."
alias or="nvim $HOME/Documents/obsidian_vault/inbox/*.md"
alias p="pnpm"
alias rd="rmdir"

alias tf=terraform

# Dev shells -- enter from anywhere
alias shell-default="nix develop $HOME/Development/Personal/kaynix#default"
alias shell-python="nix develop $HOME/Development/Personal/kaynix#python"
alias shell-web="nix develop $HOME/Development/Personal/kaynix#web"
alias shell-devops="nix develop $HOME/Development/Personal/kaynix#devops"
alias shell-rust="nix develop $HOME/Development/Personal/kaynix#rust"
