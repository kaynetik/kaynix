# sops-nix Secrets

All secret management for this flake. Encrypted secrets live in `secrets.yaml`; creation rules in `../.sops.yaml`.

## Table of Contents

- [Architecture](#architecture)
- [File layout](#file-layout)
- [Darwin activation and YubiKey](#darwin-activation-and-yubikey)
- [sops-rekey](#sops-rekey)
- [Editing secrets](#editing-secrets)
- [YubiKey identity stub](#yubikey-identity-stub)
- [Smoke-testing age + YubiKey](#smoke-testing-age--yubikey)
- [Key rotation](#key-rotation)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)

## Architecture

```
.sops.yaml                    creation rules + public recipient(s)
secrets/secrets.yaml          AES256-GCM encrypted YAML
homes/sops.nix                sops-nix HM module: secrets, activation, sops-rekey
homes/zsh-config.nix          sources decrypted conf-*.zsh at shell init
homes/static/sops/README.md   identity stub docs (linked to ~/.config/sops/age/)
```

sops-nix decrypts `secrets.yaml` during Home Manager activation into generational directories under `$TMPDIR/secrets.d/`. Symlinks make the decrypted files available at their configured `path` values:

| YAML key | sops.secrets name | Decrypted to |
|:---|:---|:---|
| `zsh_seda` | `zsh-seda` | `~/.config/zsh/conf-seda.zsh` |
| `zsh_sietch` | `zsh-sietch` | `~/.config/zsh/conf-sietch.zsh` |
| `ssh_config_work` | `ssh-work` | `~/.ssh/conf.d/work` |

The zsh secret files contain `export` statements and are sourced by `.zshrc` at shell startup.

## File layout

```
~/.config/sops/age/
    age-yubikey-identity-nix-sops.txt   private identity stub (local only)
    README.md                           symlink to homes/static/sops/README.md

~/.config/sops-nix/
    secrets/                            symlink to $TMPDIR/secrets.d/<generation>

~/.config/zsh/
    conf-seda.zsh                       symlink to secrets/zsh-seda
    conf-sietch.zsh                     symlink to secrets/zsh-sietch

~/.ssh/conf.d/
    work                                symlink to secrets/ssh-work
```

## Darwin activation and YubiKey

> [!IMPORTANT]
> YubiKey age decryption requires an interactive TTY for PIN entry and physical touch. The sops-nix LaunchAgent (`RunAtLoad`) runs in a non-interactive launchd session where `age-plugin-yubikey` cannot prompt, so decryption always fails there.

The activation override in `homes/sops.nix` handles this:

1. Attempts synchronous decryption during `darwin-rebuild switch`.
2. If decryption fails (no TTY, no YubiKey), leaves existing secrets intact instead of destroying the old generation.
3. Does not `bootout/bootstrap` the LaunchAgent -- that would trigger another doomed non-interactive run that prunes the old generation without creating a new one.
4. Installs `sops-rekey` on PATH for manual re-decryption.

The zsh init block in `homes/zsh-config.nix` auto-runs `sops-rekey` on the first interactive shell if secrets are missing, giving you a PIN/touch prompt to restore them without manual intervention.

## sops-rekey

Manual re-decryption from any interactive terminal:

```bash
sops-rekey
```

This extracts the decryption command from the sops-nix LaunchAgent plist and runs it with the correct environment. Use it after reboot if secrets are missing, or any time the symlinks are dangling.

## Editing secrets

From the repository root (paths must match `path_regex` in `.sops.yaml`):

```bash
cd ~/Development/Personal/kaynix
nix develop   # or: nix shell nixpkgs#sops nixpkgs#age nixpkgs#age-plugin-yubikey
sops secrets/secrets.yaml
```

> [!NOTE]
> This repo is a Git flake -- only tracked files are visible to `nix build` / `darwin-rebuild`. Keep `secrets.yaml` and `.sops.yaml` committed.

Use YAML multiline values:

```yaml
zsh_seda: |
  export FOO=bar

ssh_config_work: |
  Host monitoring
      User ec2-user
      HostName <internal-ip>
      IdentityFile ~/.ssh/seda-weeee
```

Decrypt to stdout without editing:

```bash
sops decrypt secrets/secrets.yaml
```

## YubiKey identity stub

The identity stub is a small file that tells `age-plugin-yubikey` which YubiKey slot holds the decryption key. It contains no private key material -- the private key never leaves the YubiKey.

**Location**: `~/.config/sops/age/age-yubikey-identity-nix-sops.txt` (defined as `sopsAgeIdentityYubikey` in `homes/sops.nix`).

### Creating or replacing the stub

```bash
mkdir -p ~/.config/sops/age
age-plugin-yubikey --identity --slot 1 > ~/.config/sops/age/age-yubikey-identity-nix-sops.txt
chmod 600 ~/.config/sops/age/age-yubikey-identity-nix-sops.txt
```

The `Recipient:` line in the stub must match the recipient in `.sops.yaml` and in the `sops.age` metadata inside `secrets.yaml`.

### Bootstrap key (fresh clone)

For initial setup without a YubiKey, generate a local age key:

```bash
mkdir -p secrets
nix shell nixpkgs#age --command age-keygen -o secrets/dev.age.key
```

Add the public key to `.sops.yaml`, run `sops updatekeys secrets/secrets.yaml`, point `sops.age.keyFile` at it in `homes/sops.nix`. Then migrate to YubiKey when ready (see [Key rotation](#key-rotation)).

The bootstrap key (`secrets/dev.age.key`) is gitignored and must not be committed.

## Smoke-testing age + YubiKey

If sops fails with a plugin error, test age directly:

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/age-yubikey-identity-nix-sops.txt"
unset SOPS_AGE_KEY SOPS_AGE_KEY_CMD

RECIP="$(age-plugin-yubikey --list | awk '/^age1yubikey1/ {print; exit}')"
printf 'smoke-test\n' > /tmp/sops-smoke.txt
age -e -r "$RECIP" -o /tmp/sops-smoke.txt.age /tmp/sops-smoke.txt
age -d -i "$SOPS_AGE_KEY_FILE" /tmp/sops-smoke.txt.age
rm -f /tmp/sops-smoke.txt /tmp/sops-smoke.txt.age
```

- If this fails: regenerate the identity stub, check PIN, touch, and slot configuration.
- If this works but sops fails: check `sops --version`, `unset SOPS_AGE_KEY`, and verify sops uses the same `age` from PATH.

> [!TIP]
> `SOPS_AGE_KEY` (inline key contents) overrides `SOPS_AGE_KEY_FILE` in some sops versions. If it is empty or stale, decryption fails silently. Always `unset` it unless you intend to use it.

## Key rotation

To add or rotate who can decrypt:

1. Edit `.sops.yaml` -- update `keys:` and `creation_rules`.
2. Run `sops updatekeys secrets/secrets.yaml` and confirm the prompt.
3. Remove old recipients from `.sops.yaml` if they should no longer have access.

To migrate from a bootstrap key to YubiKey:

1. Add the YubiKey public recipient to `.sops.yaml`.
2. Run `sops updatekeys secrets/secrets.yaml`.
3. Remove the bootstrap public key from `.sops.yaml`.
4. Set `sops.age.keyFile` in `homes/sops.nix` to the YubiKey identity stub path.
5. Delete `secrets/dev.age.key`.

## Troubleshooting

**Symlinks are dangling after reboot**

The LaunchAgent failed to decrypt (no TTY for YubiKey). Open a terminal and run `sops-rekey`, or open a new shell (auto-recovery triggers in `.zshrc`).

**`Failed to decrypt YubiKey stanza`**

- Regenerate the stub for the correct slot: `age-plugin-yubikey --identity --slot 1 > ~/.config/sops/age/age-yubikey-identity-nix-sops.txt`
- Verify the `Recipient:` line matches `.sops.yaml` and `secrets.yaml` sops metadata.
- Run the [smoke test](#smoke-testing-age--yubikey).

**`0 successful groups required, got 0`**

sops-install-secrets could not find a working decryption key. Verify:
- YubiKey is plugged in.
- `age-plugin-yubikey` is on PATH.
- The identity stub exists and is readable at the configured `keyFile` path.
- You are in an interactive terminal (not launchd, not a pipe).

**`Error getting data key` in Cursor / non-TTY terminals**

Cursor's integrated terminal is not a real TTY. YubiKey PIN/touch prompts cannot work there. Use a native terminal (Terminal.app, iTerm2, kitty, etc.) for `sops-rekey` or `darwin-rebuild switch`.

**Secrets decrypted but env vars missing**

The `conf-*.zsh` files are sourced at shell startup. If secrets were restored after the current shell started, run `source ~/.config/zsh/conf-seda.zsh` (and `conf-sietch.zsh`) or open a new terminal.

## Security notes

**`.sops.yaml` & `secrets.yaml` is safe to commit.** It contains only public age recipients & AES256-GCM ciphertext. The data encryption key is itself encrypted to the age recipients listed in the `sops.age` metadata block.

**Never commit**: `dev.age.key`, `age-yubikey-identity-nix-sops.txt`, or any file containing private key material.
