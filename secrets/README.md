# sops-nix secrets

Encrypted secrets live in `secrets.yaml`. Editing rules are defined in `../.sops.yaml`.

## Flake note

This repo is a Git flake: **only tracked files** are visible to `nix build` / `darwin-rebuild`. Keep `secrets.yaml` and `.sops.yaml` committed. Do **not** commit `dev.age.key` (it is gitignored).

## Bootstrap key (current default)

`homes/kaynetik.nix` sets `sops.age.keyFile` to:

`$HOME/Development/Personal/dot-nix/nix-darwin/secrets/dev.age.key`

Create that file locally (not in git):

```bash
cd /path/to/dot-nix/nix-darwin
mkdir -p secrets
nix shell nixpkgs#age --command age-keygen -o secrets/dev.age.key
```

The **public** key for the bootstrap recipient in `.sops.yaml` must match this key if you re-encrypt. For a fresh clone, generate your own key, add its public key to `.sops.yaml`, run `sops updatekeys secrets/secrets.yaml`, then point `sops.age.keyFile` at your key (see below).

## Edit secrets

From the `nix-darwin` directory (so paths match `path_regex` in `.sops.yaml`):

```bash
cd /path/to/dot-nix/nix-darwin
nix develop   # or: nix shell nixpkgs#sops nixpkgs#age
sops secrets/secrets.yaml
```

Keys used by Home Manager here:

- `zsh_seda` -> `~/.config/zsh/conf-seda.zsh`
- `zsh_sietch` -> `~/.config/zsh/conf-sietch.zsh`

Use YAML multiline values, for example:

```yaml
zsh_seda: |
  export FOO=bar
```

## Move off the bootstrap key

Before storing real secrets (required if the repo is public):

1. Generate a personal age key (or use `~/Library/Application Support/sops/age/keys.txt`; see [sops-nix](https://github.com/Mic92/sops-nix)).
2. Add your **public** age key to `keys` in `.sops.yaml`.
3. Run `sops updatekeys secrets/secrets.yaml`.
4. Remove the bootstrap public key from `.sops.yaml`.
5. Set `sops.age.keyFile` in `homes/kaynetik.nix` to your private key path (for example the macOS path above).
6. Delete local `secrets/dev.age.key` if you no longer use it.

## Notes

```bash
ssh-keygen -t ed25519-sk -O verify-required -C "yubi-primary" -f ~/.ssh/prim_sk_id_ed25519
ssh-keygen -t ed25519-sk -O verify-required -C "yubi-backup" -f ~/.ssh/bkup_sk_id_ed25519
```
