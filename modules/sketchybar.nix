{
  pkgs,
  username,
  hostConfig,
  ...
}: {
  services.sketchybar = {
    enable = true;
    extraPackages = [pkgs.lua5_5 pkgs.sbarlua];
  };

  launchd.user.agents.sketchybar = {
    # services.sketchybar builds the agent PATH from environment.systemPath, whose
    # "$HOME"/"$USER" entries launchd never expands, so per-user profile binaries
    # (SwitchAudioSource, jq, macmon) are unreachable from widgets. The launchd
    # module's `path` option overrides environment.PATH, so it must be fixed here;
    # list entries merge with the module's own.
    path = ["/etc/profiles/per-user/${username}/bin"];
    environment = {
      LUA_CPATH = pkgs.kaynixLib.luaCpath;
      SKETCHYBAR_THEME = hostConfig.sketchybar.theme;
    };
  };
}
