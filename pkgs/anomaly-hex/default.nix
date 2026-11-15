{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  makeWrapper,
}:
# Local Darwin adapter for Hex (https://github.com/anomalyco/hex).
#
# nixpkgs builds anomaly-hex from source for x86_64-linux only. A source build
# on Darwin is not practical: build.rs calls xcode-select and compiles Swift
# bridges against Speech, EventKit, ScreenCaptureKit and FoundationModels, none
# of which exist inside the Nix sandbox. Upstream documents the notarized
# release zip (and the Homebrew cask) as the macOS install path, so this
# repackages that zip unchanged.
#
# Drop this override once nixpkgs anomaly-hex lists aarch64-darwin in
# meta.platforms, or once upstream ships an aarch64-darwin flake package.
let
  version = "3.4.0";
in
  stdenvNoCC.mkDerivation {
    pname = "anomaly-hex";
    inherit version;

    src = fetchurl {
      url = "https://github.com/anomalyco/hex/releases/download/v${version}/hex-${version}-macos-arm64.zip";
      hash = "sha256-GrAkLcO7ARyIVokDy/Hp0wMQhnpG9RaDCYU9b4tMplA=";
    };

    nativeBuildInputs = [unzip makeWrapper];

    # The zip holds Hex.app at its top level.
    sourceRoot = ".";

    dontBuild = true;

    # The bundle is signed and notarized. Stripping or rewriting its Mach-O
    # files would invalidate the signature, so skip the fixup phase.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications $out/bin
      cp -R Hex.app $out/Applications/Hex.app

      # A wrapper rather than a symlink: the binary locates its bundle from
      # its own executable path.
      makeWrapper $out/Applications/Hex.app/Contents/MacOS/hex $out/bin/hex

      runHook postInstall
    '';

    meta = {
      description = "Local-first voice dictation (prebuilt macOS app)";
      homepage = "https://anoma.ly/hex/";
      changelog = "https://github.com/anomalyco/hex/releases/tag/v${version}";
      license = lib.licenses.mit;
      mainProgram = "hex";
      platforms = ["aarch64-darwin"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
