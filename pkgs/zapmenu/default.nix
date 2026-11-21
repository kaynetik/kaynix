{
  lib,
  stdenv,
  zig,
  darwin,
  src,
}:
# Update with: nix flake update zapmenu
# Grant Device Control and Data Access to Zapmenu.app, not the bare binary. The
# bundle is ad-hoc signed, so re-toggle the grant in System Settings after each update.
let
  # build.zig.zon is the single version source (upstream stamps Info.plist from it).
  zonVersion = line: builtins.match ''[[:space:]]*\.version = "([^"]+)",'' line;
  version = lib.head (lib.concatMap (l: lib.optionals (zonVersion l != null) (zonVersion l)) (
    lib.splitString "\n" (builtins.readFile "${src}/build.zig.zon")
  ));
in
  stdenv.mkDerivation {
    pname = "zapmenu";
    inherit version src;

    # sigtool provides the `codesign` that build.zig runs on the bundle.
    nativeBuildInputs = [zig.hook darwin.sigtool];

    zigBuildFlags = ["--release=fast"];

    # strip would invalidate the signature build.zig applied.
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
