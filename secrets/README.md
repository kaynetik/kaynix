# Secrets

Real secret wiring and ciphertext live in a separate private repo, `kaynix-vault`.
This directory only documents how the two repos connect and ships a placeholder
example.

## How the vault is consumed

- `flake.nix` declares the input
  `kaynix-vault.url = "git+ssh://git@github.com/kaynetik/kaynix-vault"`. Fetching it
  needs ssh access to the private repo; no local checkout is required to build.
- The input exports `homeManagerModules.default` (a Home Manager module that
  defines `sops.secrets`, the activation override, and `sops-rekey`). `flake.nix`
  adds it to `home-manager.sharedModules`.
- `flake.lock` pins the vault by commit and hash. It records the repo URL and a
  hash, not content.
- The vault has no inputs of its own, so it needs no `follows`.

Operations (editing secrets, YubiKey identity stub, key rotation, troubleshooting,
maintenance plan) are documented in the vault's own `README.md`.

## Files here

- `secrets-example.yaml`: placeholder ciphertext with the same shape as the vault's
  `secrets.yaml`. Values are not real.
- `../homes/sops-example.nix`: placeholder copy of the vault's `sops.nix` with generic
  names.

## CI and fresh clones

Without access to the private repo, evaluate against a stub built from the two
example files:

```bash
nix flake check --no-build --no-write-lock-file \
  --override-input kaynix-vault "path:$(scripts/vault-stub)"
```

CI runs the same override. When a public module starts depending on a new secret,
add the key to both example files in the same change.

## Updating the pinned vault

After committing and pushing in the vault:

```bash
nix flake update kaynix-vault
```

Run it as your own user, not through sudo: root has no ssh key for the private repo.
`darwin-rebuild` then reuses the locked store path instead of fetching again.

Review the `flake.lock` diff: only the `kaynix-vault` `rev` and `narHash` should change.

## Never commit

`*.age.key`, `age-yubikey-identity-*.txt`, or any file containing private key
material. `.gitignore` also blocks `secrets/secrets.yaml` and `homes/sops.nix` so the
real files cannot be re-added here by accident.
