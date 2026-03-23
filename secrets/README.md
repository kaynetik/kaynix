# sops-nix secrets

Encrypted secrets live in `secrets.yaml`. Editing rules are defined in `../.sops.yaml`.

## Flake note

This repo is a Git flake: **only tracked files** are visible to `nix build` / `darwin-rebuild`. Keep `secrets.yaml` and `.sops.yaml` committed. Do **not** commit `dev.age.key` (it is gitignored).

## Bootstrap key (current default)

`homes/kaynetik.nix` uses YubiKey identity at `~/.config/sops/age/` for normal use. For a local bootstrap key only, create it under the repo (not in git):

`$HOME/Development/Personal/kaynix/secrets/dev.age.key`

```bash
cd /path/to/kaynix
mkdir -p secrets
nix shell nixpkgs#age --command age-keygen -o secrets/dev.age.key
```

The **public** key for the bootstrap recipient in `.sops.yaml` must match this key if you re-encrypt. For a fresh clone, generate your own key, add its public key to `.sops.yaml`, run `sops updatekeys secrets/secrets.yaml`, then point `sops.age.keyFile` at your key (see below).

## Edit secrets

From the **repository root** (so paths match `path_regex` in `.sops.yaml`):

```bash
cd /path/to/kaynix
nix develop   # or: nix shell nixpkgs#sops nixpkgs#age
sops secrets/secrets.yaml
```

Keys used by Home Manager here:

- `zsh_seda` -> `~/.config/zsh/conf-seda.zsh`
- `zsh_sietch` -> `~/.config/zsh/conf-sietch.zsh`
- `ssh_config_work` -> `~/.ssh/conf.d/work` (sensitive SSH host blocks; included by `~/.ssh/config`)

Use YAML multiline values, for example:

```yaml
zsh_seda: |
  export FOO=bar

ssh_config_work: |
  Host monitoring
      User ec2-user
      HostName <internal-ip-or-hostname>
      IdentityFile ~/.ssh/seda-monitoring
      LocalForward 9443 127.0.0.1:9443
      LocalForward 7331 127.0.0.1:7331
      LocalForward 3001 127.0.0.1:3001
      LocalForward 3000 127.0.0.1:3000
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
# Default: touch + optional passphrase for the key file (see yubikey.md for verify-required tradeoffs).
ssh-keygen -t ed25519-sk -C "yubi-primary" -f ~/.ssh/prim_sk_id_ed25519
ssh-keygen -t ed25519-sk -C "yubi-backup" -f ~/.ssh/bkup_sk_id_ed25519
```
