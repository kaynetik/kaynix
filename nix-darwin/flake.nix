{
  description = "Nix for macOS [darwin]";

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
    # FIXME: Update in case username changes, or this is deployed to a new Mac.
    username = "kaynetik";
    system = "aarch64-darwin"; # aarch64-darwin (M-series) or x86_64-darwin
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
        ./modules/secrets.nix

        # Minimal inline module for user directory setup
        # Note: Shell, Git, and environment configs are managed manually outside of Nix
        {
          # Create user directories structure on system activation
          system.activationScripts.userDirectories.text = ''
            sudo -u ${username} mkdir -p /Users/${username}/Development/{Work,Personal}
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
          kubernetes-helm # Use the correct Kubernetes helm package
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
