{
  lib,
  pkgs,
  ...
}: {
  # A macOS update replaces Apple's /etc/ssl/cert.pem, so strip the distrusted
  # roots on each activation. security.pki.caCertificateBlacklist fails the
  # build here: cacert >= 3.131.1 no longer has the emSign roots (nixpkgs#249080).
  # The default Nix profile is the installer's, not the system one, so
  # darwin-rebuild does not upgrade its nss-cacert; sync it below.
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
