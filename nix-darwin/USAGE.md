# Nix-Darwin Configuration Usage Guide

## Overview

This nix-darwin configuration provides a comprehensive, declarative system management setup for macOS with the following features:

- **System-wide package management** via Nix
- **GUI applications** via Homebrew  
- **User configuration management** without Home Manager
- **Development environments** via flake dev shells
- **Secrets management** via agenix
- **Optimized caching** with proper substituters

## Quick Commands

### System Management
```bash
# Rebuild and switch configuration
darwin-rebuild switch --flake ~/.config/nix-darwin

# Update flake inputs and rebuild
cd ~/.config/nix-darwin
nix flake update
darwin-rebuild switch --flake .

# Clean up old generations
nix-collect-garbage -d
nix-store --optimise
```

### Development Environments

Enter different development environments based on your project needs:

```bash
# Default development environment (git, nix tools)
nix develop

# Web development (Node.js, Bun, TypeScript)
nix develop .#web

# DevOps environment (kubectl, helm, terraform, aws)
nix develop .#devops

# Rust development environment
nix develop .#rust
```

### Secrets Management with agenix

#### Initial Setup
1. Generate an SSH key for agenix:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/agenix
   ```

2. Create a `secrets.nix` file in the root directory:
   ```nix
   let
     kaynetik = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxx"; # Your public key
   in
   {
     "api-token.age".publicKeys = [ kaynetik ];
     "ssh-key.age".publicKeys = [ kaynetik ];
   }
   ```

3. Create encrypted secrets:
   ```bash
   # Install agenix if not already available
   nix profile install github:ryantm/agenix
   
   # Create encrypted secret
   agenix -e api-token.age
   ```

#### Using Secrets in Configuration
Uncomment and modify the examples in `modules/secrets.nix`:

```nix
age.secrets = {
  api-token = {
    file = ../secrets/api-token.age;
    owner = "kaynetik";
    group = "staff";
  };
};
```

## Module Structure

```
modules/
├── nix-core.nix      # Core Nix settings and garbage collection
├── system.nix        # macOS system defaults and preferences  
├── apps.nix          # Package management (Nix + Homebrew)
├── host-users.nix    # Host and user configuration
├── user-config.nix   # User-specific settings and shell config
└── secrets.nix       # Encrypted secrets management
```

## Shell Features

The configuration provides a rich shell environment with:

### Aliases
- `ls` → `eza --icons`
- `ll` → `eza -la --icons`
- `cat` → `bat`
- `grep` → `rg`
- `find` → `fd`
- `cd` → `z` (zoxide)

### Git Aliases
- `g` → `git`
- `gs` → `git status`
- `ga` → `git add`
- `gc` → `git commit`
- `lg` → `lazygit`

### Nix Aliases
- `rebuild` → `darwin-rebuild switch --flake ~/.config/nix-darwin`
- `nix-update` → Update flake and rebuild
- `nix-clean` → Clean up old generations
- `dev [shell]` → Enter development environment

### Functions
- `nix-edit` → Quick edit nix configuration
- `dev [environment]` → Enter specific dev environment

## Customization

### Adding New Packages
- **CLI tools**: Add to `modules/user-config.nix` under `users.users."${username}".packages`
- **GUI applications**: Add to `modules/apps.nix` under homebrew casks
- **System packages**: Add to `modules/apps.nix` under `environment.systemPackages`

### Creating New Dev Environments
Add new development shells to `flake.nix` under `devShells.${system}`:

```nix
python = pkgs.mkShell {
  buildInputs = with pkgs; [
    python311
    poetry
    black
    mypy
  ];
  shellHook = ''
    echo "🐍 Python development environment loaded!"
  '';
};
```

### Modifying System Defaults
Edit `modules/system.nix` to change macOS system preferences:

```nix
system.defaults = {
  dock.autohide = false;  # Show dock always
  finder.ShowPathbar = false;  # Hide path bar
  # ... other preferences
};
```

## Troubleshooting

### Build Errors
```bash
# Check configuration syntax
nix flake check

# Format nix files
alejandra .
```

### Substituter Issues
If you encounter cache issues:
```bash
# Clear nix cache
sudo rm -rf /nix/var/nix/profiles/per-user/root/channels
nix-channel --update
```

### Permission Issues
```bash
# Fix nix store permissions
sudo chown -R root:nixbld /nix/store
sudo chmod -R 755 /nix/store
```

## Migration Notes

### From Previous Setup
1. **Backup current configuration**: `cp -r ~/.config/nix-darwin ~/.config/nix-darwin.backup`
2. **Update flake lock**: `nix flake update`
3. **Rebuild**: `darwin-rebuild switch --flake ~/.config/nix-darwin`

### Adding Home Manager Later
If you decide to add Home Manager:
1. Remove `modules/user-config.nix` from the modules list
2. Add Home Manager input to flake
3. Migrate user configs to Home Manager format

## Performance Tips

1. **Use binary caches**: Configuration already optimized for fast builds
2. **Regular cleanup**: Run `nix-clean` monthly  
3. **Pin important software**: Use specific versions for critical tools
4. **Profile startup**: Use `time zsh -i -c exit` to check shell startup time

