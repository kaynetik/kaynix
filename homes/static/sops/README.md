# SOPS / age Identity Stub

This directory holds the YubiKey age identity stub used by sops-nix for secret decryption.

## Expected file

```
~/.config/sops/age/age-yubikey-identity-nix-sops.txt
```

This file contains no private key material -- only a reference to the YubiKey PIV slot. The private key never leaves the YubiKey.

## Creating or replacing the stub

```bash
age-plugin-yubikey --identity --slot 1 > ~/.config/sops/age/age-yubikey-identity-nix-sops.txt
chmod 600 ~/.config/sops/age/age-yubikey-identity-nix-sops.txt
```

The `Recipient:` line must match the recipient in `.sops.yaml` and in `secrets/secrets.yaml` sops metadata.

## Full documentation

See [`secrets/README.md`](../../secrets/README.md) for architecture, activation behavior, editing secrets, key rotation, and troubleshooting.
