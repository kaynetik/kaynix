{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  makeWrapper,
}:
# Repackages the notarized release zip of Hex (https://github.com/anomalyco/hex).
# A source build is not possible in the sandbox: build.rs needs xcode-select and
# the Speech, EventKit, ScreenCaptureKit and FoundationModels frameworks.
#
# Drop this once nixpkgs anomaly-hex lists aarch64-darwin in meta.platforms.
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

    sourceRoot = ".";

    dontBuild = true;

    # Fixup would invalidate the bundle's signature.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications $out/bin
      cp -R Hex.app $out/Applications/Hex.app

      # Wrapper, not a symlink: the binary finds its bundle via its own path.
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
