{
  config,
  lib,
  pkgs,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.git;
  identity = config.kaynix.identity;
  kaynixRoot = "${config.home.homeDirectory}/Development/Personal/kaynix";
in {
  options.kaynix.programs.git = {
    enable = lib.mkEnableOption "git";
  };

  config = lib.mkIf cfg.enable {
    home.file.".gitignore_global".source = "${kaynixStatic}/git/ignore_global";

    programs.git = {
      enable = true;
      lfs.enable = true;
      signing = {
        format = "openpgp";
        signByDefault = true;
        key = identity.pgp.signingKey;
      };
      # Scoped to this checkout: a global core.hooksPath would hide other
      # repos' .git/hooks. pre-commit install also refuses to run when
      # hooksPath is set, so it cannot bake store paths back in.
      # Files under .githooks must be committed as 100755; git skips
      # non-executable hooks with advice.ignoredHook.
      includes = [
        {
          condition = "gitdir:${kaynixRoot}/";
          contents.core.hooksPath = "${kaynixRoot}/.githooks";
        }
      ];
      settings = {
        user = {
          inherit (identity) name email;
        };
        credential = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {helper = "osxkeychain";};
        push = {autoSetupRemote = true;};
        init = {defaultBranch = "main";};
        core = {
          excludesFile = "${config.home.homeDirectory}/.gitignore_global";
          autocrlf = "input";
        };
        advice = {detachedHead = false;};
        http = {postBuffer = "524288000";};
      };
    };
  };
}
