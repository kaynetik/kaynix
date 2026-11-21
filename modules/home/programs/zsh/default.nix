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
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        LUA_CPATH = pkgs.kaynixLib.luaCpath;
      };

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      dotDir = "${config.xdg.configHome}/zsh";
      initContent = lib.mkMerge [
        (lib.mkBefore (lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            # Static expansion of `brew shellenv` (saves a fork per shell).
            export HOMEBREW_PREFIX="/opt/homebrew"
            export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
            export HOMEBREW_REPOSITORY="/opt/homebrew"
            export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
            export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
            [ -z "''${MANPATH-}" ] || export MANPATH=":''${MANPATH#:}"
            fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
          ''
          + ''
            source ${pkgs.zinit}/share/zinit/zinit.zsh

            # Deferred by zinit turbo. -C skips compaudit unless the dump is
            # missing or older than 24h; -u trusts nix-store fpath dirs.
            _kaynix_compinit() {
              # Needed for the (#q) age check.
              setopt localoptions extendedglob
              autoload -Uz compinit
              local zcd=''${ZDOTDIR:-$HOME}/.zcompdump
              if [[ ! -f $zcd || -n $zcd(#qN.mh+24) ]]; then
                compinit -u -d "$zcd"
              else
                compinit -C -u -d "$zcd"
              fi
            }

            # Order matters: fzf-tab needs compinit before it, widget-wrapping
            # plugins after it. zicdreplay replays compdefs queued before
            # compinit (atuin, fzf, zoxide).
            zinit ice wait'0a' lucid atinit'_kaynix_compinit; zicdreplay'
            zinit light Aloxaf/fzf-tab
            zinit ice wait'0b' lucid
            zinit light zdharma-continuum/fast-syntax-highlighting
            zinit ice wait'0c' lucid atload'_zsh_autosuggest_start'
            zinit light zsh-users/zsh-autosuggestions

            source ${config.xdg.configHome}/zsh/fzf-tab.zsh
            ulimit -n 65536
            source ${config.xdg.configHome}/zsh/setopt-history.zsh
            source ${config.xdg.configHome}/zsh/aliases.zsh
            # Fragments from kaynix-vault; `-.` rejects dangling symlinks (the
            # decrypted tree is cleared on reboot), so empty means "missing".
            _kaynix_secrets=(${config.xdg.configHome}/zsh/conf-*.zsh(N-.))
            if (( ''${#_kaynix_secrets} == 0 )) && [[ -o interactive ]] && command -v sops-rekey &>/dev/null; then
              echo "[sops] Secrets missing -- attempting re-decryption (touch YubiKey when prompted)..."
              sops-rekey && echo "[sops] Secrets restored." || echo "[sops] Decryption failed. Check YubiKey and retry with 'sops-rekey'."
              _kaynix_secrets=(${config.xdg.configHome}/zsh/conf-*.zsh(N-.))
            fi
            for _kaynix_f in "''${_kaynix_secrets[@]}"; do source "$_kaynix_f"; done
            unset _kaynix_secrets _kaynix_f
          ''))
        (lib.mkOrder 550 ''
          export GPG_TTY=$TTY
          autoload -Uz colors && colors
          setopt prompt_subst

          source ${config.xdg.configHome}/zsh/lib-git-prompt.zsh
          source ${config.xdg.configHome}/zsh/lib-kube-prompt.zsh
          source ${config.xdg.configHome}/zsh/theme-bira.zsh
        '')
        ''
          bindkey '^[[1;9A' beginning-of-line
          bindkey '^[[1;9B' end-of-line
        ''
        # ssh-agent runs under launchd (modules/home/programs/ssh).
        (lib.mkAfter ''
          export PATH="${lib.makeBinPath [pkgs.openssh pkgs.lua5_5 pkgs.lua5_5.pkgs.luarocks]}:$PATH"
        '')
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
