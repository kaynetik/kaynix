{
  lib,
  pkgs,
  ...
}: {
  # Apple ships /etc/ssl/cert.pem. A macOS update replaces it, so strip the
  # roots from CVE-2026-111943 and the eMudhra G3 leak on each activation.
  #
  # security.pki.caCertificateBlacklist is the wrong knob on this lock.
  # nix-darwin already distrusts "Comodo AAA Services root". It forwards the
  # emSign names to buildcatrust only when cacert is older than 3.131.1.
  # This nixpkgs has 3.131.1, which removed those roots; blacklisting an
  # absent name fails the build (nixpkgs#249080).
  #
  # /nix/var/nix/profiles/default is the installer profile (Lix + nss-cacert),
  # not the nix-darwin system profile. darwin-rebuild does not upgrade it.
  # Replace its bundle when it drifts from pkgs.cacert.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    cert=/etc/ssl/cert.pem
    if [[ -f $cert ]] && grep -q -E '/CN=(AAA Certificate Services|emSign ECC Root CA - G3)$' "$cert"; then
      echo "stripping distrusted roots from /etc/ssl/cert.pem" >&2
      cp -p "$cert" "$cert.bak"
      tmp=$(mktemp)
      awk '/^(###|===) /{skip=0}
        /^=== .*\/CN=(AAA Certificate Services|emSign ECC Root CA - G3)$/{skip=1}
        !skip' "$cert.bak" > "$tmp"
      if [[ ! -s $tmp ]] || ! grep -q 'BEGIN CERTIFICATE' "$tmp"; then
        echo "refusing to replace /etc/ssl/cert.pem: filter produced no certificates" >&2
        exit 1
      fi
      if grep -q -E '/CN=(AAA Certificate Services|emSign ECC Root CA - G3)$' "$tmp"; then
        echo "refusing to replace /etc/ssl/cert.pem: distrusted root still present" >&2
        exit 1
      fi
      cat "$tmp" > "$cert"
      rm -f "$tmp"
    fi

    profile=/nix/var/nix/profiles/default
    wanted="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    current=$profile/etc/ssl/certs/ca-bundle.crt
    nixenv=$profile/bin/nix-env
    if [[ -f $current && -f $profile/manifest.nix && -x $nixenv ]] && ! cmp -s "$wanted" "$current"; then
      echo "installing nss-cacert ${pkgs.cacert.version} into the default Nix profile" >&2
      "$nixenv" -p "$profile" -i "${pkgs.cacert}"
    fi
  '';
}
