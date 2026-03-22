# SOPS / age identity layout

## What belongs in git (`homes/static/sops/`)

Only **documentation** (this file). Do **not** add `age-yubikey-identity*.txt` or any other age identity stub here. Those files are **machine-local** and must **not** be committed.

## Where the YubiKey identity stub lives

The path is defined once in `homes/kaynetik.nix` as `sopsAgeIdentityYubikey` (currently under `$XDG_CONFIG_HOME/sops/age/`). **Home Manager** `sops.age.keyFile` points at that path. Change the let-binding there if you standardize on a different layout.

A copy of this README is linked into `~/.config/sops/age/README.md` on activation so the expected location stays discoverable next to the identity file.

## Creating or replacing the stub

1. Plug in the YubiKey (PIV + `age-plugin-yubikey` setup complete; see repo root `yubikey.md`).
2. Use a **full path** when saving, or move the file afterward:

   ```bash
   mkdir -p ~/.config/sops/age
   age-plugin-yubikey --identity --slot SLOT > ~/.config/sops/age/age-yubikey-identity-nix-sops.txt
   chmod 600 ~/.config/sops/age/age-yubikey-identity-nix-sops.txt
   ```

3. Match the filename to `sopsAgeIdentityYubikey` in `kaynetik.nix`.
4. Recipients for `nix-darwin/.sops.yaml` come from `age-plugin-yubikey --list`.

## Related docs

- `nix-darwin/secrets/README.md` -- editing `secrets.yaml`, bootstrap age key
- `yubikey.md` (repo root) -- OpenSSH `sk-*`, PIV vs FIDO, `age-plugin-yubikey`, troubleshooting

## End-to-end flows (YubiKey age + SOPS)

Use one shell session for all commands below. From `nix-darwin/` when touching `secrets/secrets.yaml` (matches `path_regex` in `.sops.yaml`).

### 0. Environment (every session)

```bash
cd ~/Development/Personal/dot-nix/nix-darwin
export PATH="$(nix build nixpkgs#age-plugin-yubikey --no-link --print-out-paths | tail -1)/bin:$(nix build nixpkgs#age --no-link --print-out-paths | tail -1)/bin:$PATH"
unset SOPS_AGE_KEY SOPS_AGE_KEY_CMD
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/age-yubikey-identity-nix-sops.txt"
```

`SOPS_AGE_KEY` (contents) overrides `SOPS_AGE_KEY_FILE` in some SOPS versions. If `SOPS_AGE_KEY` is empty or stale, decryption fails in confusing ways. Always `unset` it unless you mean to use it.

Plug in the YubiKey before decrypt; use **PIV PIN** and **touch** when prompted (per your slot policy).

### 1. See plaintext (what is encrypted)

Decrypt **stdout** (does not write a plain file to disk):

```bash
sops decrypt secrets/secrets.yaml
```

Edit via decrypt-in-editor (still no long-lived plaintext file unless you save a copy):

```bash
sops secrets/secrets.yaml
```

To keep a **temporary** plain copy for inspection (remove after):

```bash
sops decrypt secrets/secrets.yaml > /tmp/secrets.plain.yaml
# inspect, then:
shred -u /tmp/secrets.plain.yaml 2>/dev/null || rm -P /tmp/secrets.plain.yaml 2>/dev/null || rm /tmp/secrets.plain.yaml
```

### 2. Validate age + YubiKey **before** blaming SOPS

If SOPS fails with a YubiKey plugin error, test **age** alone (same `PATH`, same identity, same recipient as in `.sops.yaml`):

```bash
RECIP="$(age-plugin-yubikey --list | awk '/^age1yubikey1/ {print; exit}')"
printf 'sops-yubikey-age-smoke-test\n' > /tmp/sops-smoke.txt
age -e -r "$RECIP" -o /tmp/sops-smoke.txt.age /tmp/sops-smoke.txt
age -d -i "$SOPS_AGE_KEY_FILE" /tmp/sops-smoke.txt.age
rm -f /tmp/sops-smoke.txt /tmp/sops-smoke.txt.age
```

Use the same recipient string as in `nix-darwin/.sops.yaml` if you prefer to copy it manually.

- If **this fails**: fix identity file (regenerate with `age-plugin-yubikey --identity --slot N`), PIN, touch, or TDES management key (see `yubikey.md`). SOPS cannot work until this passes.
- If **this works** but **SOPS** fails: check `sops --version`, `unset SOPS_AGE_KEY`, and that `sops` uses the same `age` from `PATH`.

### 3. Encryption flow (normal ongoing work)

Recipients come from `nix-darwin/.sops.yaml`. After changing secrets:

```bash
sops secrets/secrets.yaml
```

Save and exit; SOPS re-encrypts using the rules in `.sops.yaml`.

To add or rotate **who** can decrypt:

1. Edit `.sops.yaml` (`keys:` + `creation_rules`).
2. Run:

```bash
sops updatekeys secrets/secrets.yaml
```

Confirm the prompt (or use `sops updatekeys --yes` if you accept non-interactive).

### 4. Validate “all good” after a switch

1. `sops decrypt secrets/secrets.yaml` succeeds with only the YubiKey (and env from section 0).
2. `darwin-rebuild switch` (or `home-manager switch`) completes; **sops-nix** writes `~/.config/zsh/conf-seda.zsh` and `conf-sietch.zsh`.
3. Optional: open those two paths and confirm content matches what you expect.

### 5. If `Failed to decrypt YubiKey stanza` persists

- Regenerate the stub for the **same slot** that holds the key:  
  `age-plugin-yubikey --identity --slot 1 > ~/.config/sops/age/age-yubikey-identity-nix-sops.txt`  
  then `chmod 600` that file.
- Confirm `cat ~/.config/sops/age/age-yubikey-identity-nix-sops.txt` **Recipient:** line matches the recipient inside `secrets.yaml` under `sops.age` and in `.sops.yaml`.
- Avoid switching to another applet (e.g. FIDO-only use) between PIN entry and decrypt if your key clears PIV session (see `age-plugin-yubikey` README).
- Run section 2 smoke test again.
