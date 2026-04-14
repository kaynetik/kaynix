{
  config,
  lib,
  pkgs,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.zsh;
in {
  options.kaynix.programs.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables =
      {}
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        LUA_CPATH = "${pkgs.lua5_5}/lib/lua/5.5/?.so;${pkgs.lua5_5}/lib/lua/5.5/loadall.so;${pkgs.sbarlua}/lib/lua/5.5/?.so;./?.so";
      };

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      dotDir = "${config.xdg.configHome}/zsh";
      initContent = lib.mkMerge [
        (lib.mkBefore ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
          source ${pkgs.zinit}/share/zinit/zinit.zsh
          autoload -Uz compinit && compinit -u
          zinit light zsh-users/zsh-autosuggestions
          zinit light zdharma-continuum/fast-syntax-highlighting
          zinit light Aloxaf/fzf-tab
          source ${config.xdg.configHome}/zsh/fzf-tab.zsh
          ulimit -n 65536
          source ${config.xdg.configHome}/zsh/setopt-history.zsh
          source ${config.xdg.configHome}/zsh/aliases.zsh
          if [[ ! -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && [[ -o interactive ]] && command -v sops-rekey &>/dev/null; then
            echo "[sops] Secrets missing -- attempting re-decryption (touch YubiKey when prompted)..."
            sops-rekey && echo "[sops] Secrets restored." || echo "[sops] Decryption failed. Check YubiKey and retry with 'sops-rekey'."
          fi
          [[ -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && source ${config.xdg.configHome}/zsh/conf-seda.zsh
          [[ -r ${config.xdg.configHome}/zsh/conf-sietch.zsh ]] && source ${config.xdg.configHome}/zsh/conf-sietch.zsh
        '')
        (lib.mkOrder 550 ''
          export GPG_TTY=$(tty)
          autoload -Uz colors && colors
          setopt prompt_subst

          source ${config.xdg.configHome}/zsh/lib-git-prompt.zsh
          [[ -r ${config.xdg.configHome}/zsh/conf-kube-ctx-aliases.zsh ]] && source ${config.xdg.configHome}/zsh/conf-kube-ctx-aliases.zsh
          source ${config.xdg.configHome}/zsh/lib-kube-prompt.zsh
          source ${config.xdg.configHome}/zsh/theme-bira.zsh
        '')
        ''
          bindkey '^[[1;9A' beginning-of-line
          bindkey '^[[1;9B' end-of-line
        ''
        (lib.mkAfter (''
            export PATH="${lib.makeBinPath [pkgs.openssh pkgs.lua5_5 pkgs.lua5_5.pkgs.luarocks]}:$PATH"
          ''
          + lib.optionalString pkgs.stdenv.isDarwin ''
            if [[ -o interactive ]]; then
              export SSH_AUTH_SOCK="${config.home.homeDirectory}/.ssh/nix-ssh-agent.sock"
              _nix_ssh_agent="${pkgs.openssh}/bin/ssh-agent"
              _nix_ssh_add="${pkgs.openssh}/bin/ssh-add"
              _need_agent=0
              if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
                _need_agent=1
              elif ! _ssh_add_out=$("$_nix_ssh_add" -l 2>&1); then
                [[ "$_ssh_add_out" == *'The agent has no identities.'* ]] || _need_agent=1
              fi
              if [[ "$_need_agent" -eq 1 ]]; then
                rm -f "$SSH_AUTH_SOCK"
                eval "$("$_nix_ssh_agent" -s -a "$SSH_AUTH_SOCK")" >/dev/null
              fi
              unset _nix_ssh_agent _nix_ssh_add _need_agent _ssh_add_out
            fi
          ''))
      ];
    };

    xdg.configFile."zsh/aliases.zsh".source = "${kaynixStatic}/zsh/aliases.zsh";
    xdg.configFile."zsh/setopt-history.zsh".source = "${kaynixStatic}/zsh/setopt-history.zsh";
    xdg.configFile."zsh/lib-git-prompt.zsh".source = "${kaynixStatic}/zsh/lib-git-prompt.zsh";
    xdg.configFile."zsh/lib-kube-prompt.zsh".source = "${kaynixStatic}/zsh/lib-kube-prompt.zsh";
    xdg.configFile."zsh/theme-bira.zsh".source = "${kaynixStatic}/zsh/theme-bira.zsh";
    xdg.configFile."zsh/fzf-tab.zsh".source = "${kaynixStatic}/zsh/fzf-tab.zsh";
  };
}
