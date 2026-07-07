{
  config,
  lib,
  pkgs,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.git;
  identity = config.kaynix.identity;
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
      settings = {
        user = {
          inherit (identity) name email;
        };
        credential = lib.mkIf pkgs.stdenv.isDarwin {helper = "osxkeychain";};
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
