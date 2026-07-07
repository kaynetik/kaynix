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
        LUA_CPATH = pkgs.kaynixLib.luaCpath;
      };

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      dotDir = "${config.xdg.configHome}/zsh";
      initContent = lib.mkMerge [
        (lib.mkBefore (lib.optionalString pkgs.stdenv.isDarwin ''
            # Static expansion of `eval "$(/opt/homebrew/bin/brew shellenv)"`:
            # saves a brew + path_helper fork on every shell. Values are fixed
            # by the /opt/homebrew prefix; re-check with `brew shellenv` if
            # Homebrew ever relocates.
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

            # Deferred completion init, run by zinit turbo after the first
            # prompt. -C reuses the dump without the compaudit pass unless the
            # dump is missing or older than 24h; -u trusts nix-store fpath dirs.
            _kaynix_compinit() {
              # extendedglob is required for the (#q) age check; scoped so it
              # does not leak into interactive globbing.
              setopt localoptions extendedglob
              autoload -Uz compinit
              local zcd=''${ZDOTDIR:-$HOME}/.zcompdump
              if [[ ! -f $zcd || -n $zcd(#qN.mh+24) ]]; then
                compinit -u -d "$zcd"
              else
                compinit -C -u -d "$zcd"
              fi
            }

            # Turbo-load plugins off the first-prompt path. Order matters:
            # fzf-tab wants compinit before it and widget-wrapping plugins
            # (fast-syntax-highlighting, autosuggestions) after it. zicdreplay
            # replays compdefs queued by integrations that ran before compinit
            # (atuin, fzf, zoxide).
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
            if [[ ! -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && [[ -o interactive ]] && command -v sops-rekey &>/dev/null; then
              echo "[sops] Secrets missing -- attempting re-decryption (touch YubiKey when prompted)..."
              sops-rekey && echo "[sops] Secrets restored." || echo "[sops] Decryption failed. Check YubiKey and retry with 'sops-rekey'."
            fi
            [[ -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && source ${config.xdg.configHome}/zsh/conf-seda.zsh
            [[ -r ${config.xdg.configHome}/zsh/conf-sietch.zsh ]] && source ${config.xdg.configHome}/zsh/conf-sietch.zsh
            [[ -r ${config.xdg.configHome}/zsh/conf-flowd.zsh ]] && source ${config.xdg.configHome}/zsh/conf-flowd.zsh
          ''))
        (lib.mkOrder 550 ''
          export GPG_TTY=$TTY
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
        # The ssh-agent itself is a supervised launchd agent (see
        # modules/home/programs/ssh); SSH_AUTH_SOCK is a static session
        # variable there, so shells no longer probe or spawn agents.
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
