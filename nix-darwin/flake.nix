{
  description = "Nix for macOS configuration";

  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    self,
    nixpkgs,
    darwin,
    agenix,
    ...
  }: let
    # TODO replace with your own username, system and hostname
    username = "kaynetik";
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    hostname = "knt-mbp";

    specialArgs =
      inputs
      // {
        inherit username hostname;
      };
  in {
    darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        agenix.darwinModules.default
        ./modules/nix-core.nix
        ./modules/system.nix
        ./modules/apps.nix
        ./modules/host-users.nix
        
        # Inline secrets module to avoid path resolution issues
        {
          environment.systemPackages = with inputs.nixpkgs-darwin.legacyPackages.${system}; [
            agenix
          ];
          # Create secrets directory if it doesn't exist
          system.activationScripts.createSecretsDir.text = ''
            mkdir -p /Users/${username}/.config/nix-darwin/secrets
            chown ${username}:staff /Users/${username}/.config/nix-darwin/secrets
            chmod 700 /Users/${username}/.config/nix-darwin/secrets
          '';
        }
        
        # Inline basic user config module to avoid path resolution issues
        {
          # Add user-specific packages (extending the existing user definition)
          environment.systemPackages = with inputs.nixpkgs-darwin.legacyPackages.${system}; [
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

          # Git configuration (managed manually - nix-darwin doesn't have programs.git)
          # Users can configure git manually or use Home Manager for declarative git config

          # Environment variables for the user
          environment.variables = {
            EDITOR = "vim";
            VISUAL = "vim";
            LANG = "en_US.UTF-8";
            LC_ALL = "en_US.UTF-8";
            FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
            FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
            BAT_THEME = "TwoDark";
          };

          # Create user directories structure
          system.activationScripts.userDirectories.text = ''
            sudo -u ${username} mkdir -p /Users/${username}/Development/{Work,Personal,Learning}
            sudo -u ${username} mkdir -p /Users/${username}/Development/Nix/{flakes,shells}
            sudo -u ${username} mkdir -p /Users/${username}/.config/{git,zsh}
            
            if [ ! -f /Users/${username}/.gitconfig ]; then
              sudo -u ${username} touch /Users/${username}/.gitconfig
            fi
          '';
        }
      ];
    };

    # Development shells for different projects
    devShells.${system} = let
      pkgs = import inputs.nixpkgs-darwin {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          alejandra
          nil # Nix LSP
        ];
        shellHook = ''
          echo "🚀 Default development environment loaded!"
          echo "Available tools: git, alejandra (nix formatter), nil (nix LSP)"
        '';
      };

      # Web development environment
      web = pkgs.mkShell {
        buildInputs = with pkgs; [
          nodejs_20
          bun
          typescript
          tailwindcss
          git
        ];
        shellHook = ''
          echo "🌐 Web development environment loaded!"
          echo "Node: $(node --version), Bun: $(bun --version)"
        '';
      };

      # Systems/DevOps environment
      devops = pkgs.mkShell {
        buildInputs = with pkgs; [
          kubectl
          kubernetes-helm  # Use the correct Kubernetes helm package
          terraform
          awscli2
          docker
          k9s
          git
        ];
        shellHook = ''
          echo "🔧 DevOps environment loaded!"
          echo "Available: kubectl, helm, terraform, aws, docker, k9s"
        '';
      };

      # Rust development environment
      rust = pkgs.mkShell {
        buildInputs = with pkgs; [
          rustc
          cargo
          rustfmt
          rust-analyzer
          clippy
          git
        ];
        shellHook = ''
          echo "🦀 Rust development environment loaded!"
          echo "Rust: $(rustc --version)"
        '';
      };
    };

    # nix code formatter
    formatter.${system} = inputs.nixpkgs-darwin.legacyPackages.${system}.alejandra;
  };
}
