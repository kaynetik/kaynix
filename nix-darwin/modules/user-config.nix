{ pkgs, username, ... }:

#############################################################
#
#  User Configuration Management (without Home Manager)
#  Manages user-specific configurations and dotfiles
#
#############################################################

{
  # User-specific packages that don't need to be system-wide
  users.users."${username}".packages = with pkgs; [
    # Development tools for user
    jq
    yq
    # Text processing
    ripgrep
    fd
    bat
    eza
    # Network tools
    curl
    wget
    # Terminal utilities
    zoxide
    fzf
    # Git tools
    lazygit
    gh
  ];

  # Shell configuration for the user
  users.users."${username}".shell = pkgs.zsh;

  # Global shell configurations that apply to the user
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    
    # Global zsh configuration
    interactiveShellInit = ''
      # Enable vi mode
      bindkey -v
      
      # History settings
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE
      
      # Directory navigation
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      
      # Initialize zoxide if available
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init zsh)"
      fi
      
      # Initialize fzf if available
      if command -v fzf >/dev/null 2>&1; then
        source <(fzf --zsh)
      fi
      
      # Aliases
      alias ls="eza --icons"
      alias ll="eza -la --icons"
      alias tree="eza --tree --icons"
      alias cat="bat"
      alias grep="rg"
      alias find="fd"
      alias cd="z"
      
      # Git aliases
      alias g="git"
      alias gs="git status"
      alias ga="git add"
      alias gc="git commit"
      alias gp="git push"
      alias gl="git pull"
      alias gd="git diff"
      alias gco="git checkout"
      alias gb="git branch"
      alias lg="lazygit"
      
      # Nix aliases
      alias nix-shell="nix develop"
      alias rebuild="darwin-rebuild switch --flake ~/.config/nix-darwin"
      alias nix-update="cd ~/.config/nix-darwin && nix flake update && darwin-rebuild switch --flake ."
      alias nix-clean="nix-collect-garbage -d && nix-store --optimise"
      
      # Utility functions
      # Quick edit nix config
      nix-edit() {
        cd ~/.config/nix-darwin
        ''${EDITOR:-vim} .
      }
      
      # Enter development environment
      dev() {
        if [ -z "$1" ]; then
          nix develop
        else
          nix develop ".#$1"
        fi
      }
    '';
    
    promptInit = ''
      # Simple prompt with git branch
      autoload -Uz vcs_info
      precmd() { vcs_info }
      zstyle ':vcs_info:git:*' formats ' (%b)'
      setopt PROMPT_SUBST
      PROMPT='%F{blue}%~%f%F{red}''${vcs_info_msg_0_}%f %# '
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        autocrlf = false;
      };
      user = {
        # These can be overridden by local git config
        name = "${username}";
        # email = "your-email@example.com"; # Uncomment and set your email
      };
    };
  };

  # Environment variables for the user
  environment.variables = {
    # Default editor
    EDITOR = "vim";
    VISUAL = "vim";
    
    # Development environment variables
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    
    # Nix-related
    NIX_PATH = "nixpkgs=flake:nixpkgs:nixpkgs-unstable";
    
    # Tool configurations
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
    BAT_THEME = "TwoDark";
  };

  # Create user directories structure
  system.activationScripts.userDirectories.text = ''
    # Create common development directories for the user
    sudo -u ${username} mkdir -p /Users/${username}/Development/{Work,Personal,Learning}
    sudo -u ${username} mkdir -p /Users/${username}/Development/Nix/{flakes,shells}
    sudo -u ${username} mkdir -p /Users/${username}/.config/{git,zsh}
    
    # Create a basic gitconfig if it doesn't exist
    if [ ! -f /Users/${username}/.gitconfig ]; then
      sudo -u ${username} touch /Users/${username}/.gitconfig
    fi
  '';
}

