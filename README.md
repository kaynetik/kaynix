# Nix Darwin Kickstarter - Minimal

 A basic configuration comprising essential settings for initiating nix-darwin. It can be safely deployed to your system.

## How to Use

1. Install Nix package manager via [Nix Official](https://nixos.org/download.html#nix-install-macos) or [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer).
2. Read the Nix modules under `modules/`, `homes/`, and `flake.nix`, and understand what they do.
   1. If you have trouble understanding, [ryan4yin/nixos-and-flakes-book](https://github.com/ryan4yin/nixos-and-flakes-book) is a good resource to learn nix and flakes.
3. Install Homebrew, see <https://brew.sh/>
   1. Homebrew is required to install most of the GUI apps, App Store's apps, and some CLI apps that are not available in nix's package repository `nixpkgs`.
4. Run the following command in the root of your nix configuration to start your nix-darwin journey(please change `hostname` to your hostname):
   ```bash
	nix build .#darwinConfigurations.hostname.system \
		--extra-experimental-features 'nix-command flakes'

	./result/sw/bin/darwin-rebuild switch --flake .#hostname
   ```

To simplify the command, adding the following content by create a `Makefile` in the root of your nix configuration:

```makefile
# please change 'hostname' to your hostname
deploy:
	nix build .#darwinConfigurations.hostname.system \
	   --extra-experimental-features 'nix-command flakes'

	./result/sw/bin/darwin-rebuild switch --flake .#hostname
```

Then you can run `make deploy` in the root of your nix configuration to deploy your configuration.

## Configuration Structure

The flake lives at the **repository root**. Typical layout:

```bash
› tree
.
├── flake.lock
├── flake.nix          # entry point; hostname and inputs
├── modules/           # nix-darwin system modules
│   ├── apps.nix
│   ├── host-users.nix
│   ├── nix-core.nix
│   ├── system.nix
│   └── ...
├── homes/             # Home Manager user config
│   └── kaynetik.nix
├── secrets/           # sops-encrypted secrets (see secrets/README.md)
├── scripts/           # helper scripts wired into home.packages
└── README.md
```
