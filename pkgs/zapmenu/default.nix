{
  lib,
  stdenv,
  zig,
  darwin,
  src,
}:
# zapmenu (https://github.com/kaynetik/zapmenu), built from the `zapmenu` flake
# input (flake = false). Nothing to maintain here; update with:
#
#   nix flake update zapmenu
#
# Grant Device Control and Data Access to Zapmenu.app, not the bare binary.
# The bundle is ad-hoc signed, so the grant is pinned to this build: re-toggle it in System Settings after each update.
let
  # build.zig.zon is the single version source (upstream stamps Info.plist from
  # it), so read it instead of repeating the version here.
  zonVersion = line: builtins.match ''[[:space:]]*\.version = "([^"]+)",'' line;
  version = lib.head (lib.concatMap (l: lib.optionals (zonVersion l != null) (zonVersion l)) (
    lib.splitString "\n" (builtins.readFile "${src}/build.zig.zon")
  ));
in
  stdenv.mkDerivation {
    pname = "zapmenu";
    inherit version src;

    # zig.hook supplies the `zig build` phases; sigtool provides the
    # `codesign` that build.zig runs on the bundle.
    nativeBuildInputs = [zig.hook darwin.sigtool];

    # Match upstream release builds (the hook default is ReleaseSafe).
    zigBuildFlags = ["--release=fast"];

    # strip runs after build.zig signed the bundle and would invalidate it.
    dontStrip = true;

    postInstall = ''
      mkdir -p $out/Applications
      mv $out/Zapmenu.app $out/Applications/
    '';

    meta = {
      description = "Blocks the macOS auto-hide menu bar from appearing at the top screen edge";
      homepage = "https://github.com/kaynetik/zapmenu";
      license = lib.licenses.mit;
      mainProgram = "zapmenu";
      platforms = lib.platforms.darwin;
    };
  }
