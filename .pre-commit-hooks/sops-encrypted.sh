#!/usr/bin/env bash
# Fail if a file under secrets/ lacks sops metadata or carries a plaintext value.
# Offending keys are reported by line number and name only, never by value.
set -euo pipefail

status=0
for file in "$@"; do
  if ! grep -q '^sops:' "$file"; then
    echo "ERROR: $file has no sops metadata. Encrypt it: sops encrypt -i $file"
    status=1
    continue
  fi

  plain=$(awk '
    /^sops:/ { in_sops = 1; next }
    /^[^[:space:]#]/ { in_sops = 0 }
    in_sops { next }
    /^[[:space:]]*(#|$)/ { next }
    /:[[:space:]]*$/ { next }
    /ENC\[AES256_GCM,/ { next }
    { line = $0; sub(/:.*/, "", line); gsub(/^[[:space:]-]+/, "", line); print "  line " FNR ": " line }
  ' "$file")

  if [ -n "$plain" ]; then
    echo "ERROR: $file has unencrypted values:"
    echo "$plain"
    status=1
  fi
done

exit "$status"
