{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file = {
    ".zshenv".text = ''
      export ZDOTDIR="${config.home.homeDirectory}/.config/zsh"
      [[ -r "$ZDOTDIR/.zshenv" ]] && . "$ZDOTDIR/.zshenv"
    '';
    ".zshrc".text = ''
      export ZDOTDIR="${config.home.homeDirectory}/.config/zsh"
      [[ -r "$ZDOTDIR/.zshrc" ]] && . "$ZDOTDIR/.zshrc"
    '';
  };

  home.sessionVariables = {
    ZSH_DISABLE_COMPFIX = "true";
    DISABLE_MAGIC_FUNCTIONS = "true";
    HIST_STAMPS = "dd.mm.yyyy";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";
    "oh-my-zsh" = {
      enable = true;
      theme = "bira";
      plugins = ["git"];
    };
    # zinit stays on Homebrew. Order: mkBefore (early), mkOrder 550 (before oh-my-zsh), tail (after HM hooks).
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        source /opt/homebrew/opt/zinit/zinit.zsh
        zinit light zsh-users/zsh-autosuggestions
        zinit light zdharma-continuum/fast-syntax-highlighting
        zinit light marlonrichert/zsh-autocomplete
        ulimit -n 65536
        source ${config.xdg.configHome}/zsh/setopt-history.zsh
        source ${config.xdg.configHome}/zsh/aliases.zsh
        # See secrets/README.md#darwin-activation-and-yubikey
        if [[ ! -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && [[ -o interactive ]] && command -v sops-rekey &>/dev/null; then
          echo "[sops] Secrets missing -- attempting re-decryption (touch YubiKey when prompted)..."
          sops-rekey && echo "[sops] Secrets restored." || echo "[sops] Decryption failed. Check YubiKey and retry with 'sops-rekey'."
        fi
        [[ -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && source ${config.xdg.configHome}/zsh/conf-seda.zsh
        [[ -r ${config.xdg.configHome}/zsh/conf-sietch.zsh ]] && source ${config.xdg.configHome}/zsh/conf-sietch.zsh
      '')
      (lib.mkOrder 550 ''
        zstyle ':omz:update' mode auto
        export GPG_TTY=$(tty)
      '')
      ''
        # Atuin, zoxide, fzf: Home Manager adds hooks when programs.*.enableZshIntegration is true.
        bindkey '^[[1;9A' beginning-of-line
        bindkey '^[[1;9B' end-of-line
      ''
      (lib.mkAfter (''
          # After brew shellenv and oh-my-zsh: macOS /usr/bin OpenSSH has no working FIDO provider.
          # Prepend nixpkgs openssh so ssh, ssh-keygen, scp, sftp match (libfido2-backed sk keys).
          # Also prepend lua/luarocks so the nix versions win over any homebrew remnants.
          export PATH="${lib.makeBinPath [pkgs.openssh pkgs.lua pkgs.luarocks]}:$PATH"
        ''
        + lib.optionalString pkgs.stdenv.isDarwin ''
          # launchd's /usr/bin/ssh-agent can disagree with nix ssh/ssh-add on ed25519-sk signing; use one OpenSSH for both.
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

  xdg.configFile."zsh/aliases.zsh".source = ./static/zsh/aliases.zsh;
  xdg.configFile."zsh/setopt-history.zsh".source = ./static/zsh/setopt-history.zsh;
}
