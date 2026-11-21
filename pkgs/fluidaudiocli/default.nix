{
  lib,
  fetchFromGitHub,
  fetchzip,
  swift,
  swiftpm,
  perl,
}:
# Upstream ships no binary; built from the release tag.
#
# Update: bump `version`, set `src.hash` to lib.fakeHash, then `nix build`. If
# the NemoTextProcessing binaryTarget in Package@swift-6.2.swift changed, update
# `nemoTextProcessing` to match.
let
  version = "0.18.3";

  # SwiftPM cannot download the manifest's binaryTarget in the sandbox, so it is
  # fetched here and postPatch points the manifest at the local copy.
  # upstream checksum: 5fa8c10d4ec26c1bb2413125f351a7222a4c68a23b74476680fbada7e26fc6aa
  nemoTextProcessing = fetchzip {
    url = "https://github.com/FluidInference/text-processing-rs/releases/download/v0.3.1/NemoTextProcessing.xcframework.zip";
    hash = "sha256-LdmMYCuBSY54H9l4jqT053mxs8UhEofJec3w48BbQgI=";
    stripRoot = false;
  };
in
  swift.stdenv.mkDerivation (finalAttrs: {
    pname = "fluidaudiocli";
    inherit version;

    src = fetchFromGitHub {
      owner = "FluidInference";
      repo = "FluidAudio";
      rev = "v${finalAttrs.version}";
      hash = "sha256-WtUPEfJESHqdW+d6x3nHuuZ9pQP/dhScJNJnKlhn72Y=";
    };

    nativeBuildInputs = [swift swiftpm perl];

    # The default backend verifies xcframework signatures, which fails in the sandbox.
    swiftpmFlags = ["--build-system" "native"];

    postPatch = ''
      cp -r ${nemoTextProcessing}/NemoTextProcessing.xcframework Vendor-NemoTextProcessing.xcframework
      perl -0pi -e 's/url:\s*"[^"]*",\s*checksum:\s*"[^"]*"/path: "Vendor-NemoTextProcessing.xcframework"/' \
        Package@swift-6.2.swift
      grep -q 'Vendor-NemoTextProcessing' Package@swift-6.2.swift
    '';

    # The resource bundle is looked up relative to the executable, so both live
    # under libexec.
    installPhase = ''
      runHook preInstall

      binPath="$(swiftpmBinPath)"
      mkdir -p $out/libexec/fluidaudiocli $out/bin
      cp "$binPath/fluidaudiocli" $out/libexec/fluidaudiocli/
      cp -r "$binPath"/*.bundle $out/libexec/fluidaudiocli/
      ln -s $out/libexec/fluidaudiocli/fluidaudiocli $out/bin/fluidaudiocli

      runHook postInstall
    '';

    meta = {
      description = "FluidAudio CLI: on-device ASR, TTS and diarization for Apple platforms";
      homepage = "https://github.com/FluidInference/FluidAudio";
      changelog = "https://github.com/FluidInference/FluidAudio/releases/tag/v${version}";
      license = lib.licenses.asl20;
      mainProgram = "fluidaudiocli";
      platforms = ["aarch64-darwin"];
    };
  })
