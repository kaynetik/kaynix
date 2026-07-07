{
  config,
  lib,
  pkgs,
  kaynixStatic,
  hostConfig,
  ...
}: let
  cfg = config.kaynix.programs.sketchybar;

  # Vendored FelixKratz event provider: pushes en0 throughput to sketchybar over
  # its Mach port every N seconds (spawned by items/widgets/wifi.lua, which finds
  # it on the LaunchAgent PATH). Packaged here so the bar never compiles anything
  # at startup and the binary has store provenance like every other package.
  network-load = pkgs.stdenv.mkDerivation {
    pname = "sketchybar-network-load";
    version = "0-unstable-2026-07-04";
    src = ./network_load;

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      $CC -std=c99 -O3 network_load.c -o network_load
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 network_load $out/bin/network_load
      runHook postInstall
    '';

    meta = {
      description = "SketchyBar network throughput event provider";
      platforms = lib.platforms.darwin;
      mainProgram = "network_load";
    };
  };
in {
  options.kaynix.programs.sketchybar = {
    enable = lib.mkEnableOption "sketchybar";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = [network-load];

    xdg.configFile."sketchybar" = {
      source = "${kaynixStatic}/sketchybar";
      recursive = true;
    };

    # Matches launchd (modules/sketchybar.nix); set theme in flake host `config.sketchybar.theme`.
    home.sessionVariables.SKETCHYBAR_THEME = hostConfig.sketchybar.theme;
  };
}
