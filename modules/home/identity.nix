{
  config,
  lib,
  ...
}: {
  # Identity for git, jujutsu and ssh. homes/static/git/template.gitconfig is
  # kept in sync by hand. Exported as `homeModules.kaynix-identity`.
  options.kaynix.identity = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "kaynetik";
      description = "Author name for VCS metadata (git/jj user.name).";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "aleksandar@nesovic.dev";
      description = "Author email for VCS metadata (git/jj user.email).";
    };

    pgp.signingKey = lib.mkOption {
      type = lib.types.str;
      default = "FC04210D2782C032";
      description = ''
        OpenPGP long key id used to sign git commits and tags.
        Full fingerprint: 3E32D82218ED44AA9E8C147DFC04210D2782C032.
      '';
    };

    ssh.keyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.ssh/prim_sk_id_ed25519";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.ssh/prim_sk_id_ed25519"'';
      description = ''
        Absolute path to the primary ssh private key. Used as the jj signing
        key and as the IdentityFile for GitHub hosts.
      '';
    };
  };
}
