{
  lib,
  fetchFromGitHub,
  fetchzip,
  swift,
  swiftpm,
  perl,
}:
# FluidAudio command line tool (ASR, TTS, diarization on CoreML).
#
# Upstream publishes no binary and no Homebrew formula; the documented install
# is `swift build -c release`. This builds that product from the release tag.
#
# Update routine:
#   1. Bump `version` and set `src.hash` to lib.fakeHash, then `nix build`.
#   2. If Package@swift-6.2.swift changed the NemoTextProcessing binaryTarget
#      (version in the URL, checksum), update `nemoTextProcessing` to match.
#
# The manifest declares the NeMo text-processing engine as a binaryTarget with
# a download URL. SwiftPM cannot fetch it inside the sandbox, so it is fetched
# here with a pinned hash and the manifest is rewritten to a local path.
let
  version = "0.18.3";

  # Matches the binaryTarget in Package@swift-6.2.swift (picked by Swift 6.2+).
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

    # The default swift-build backend verifies xcframework signatures through
    # system trust services, which fail inside the sandbox. The native backend
    # links the local xcframework directly.
    swiftpmFlags = ["--build-system" "native"];

    postPatch = ''
      cp -r ${nemoTextProcessing}/NemoTextProcessing.xcframework Vendor-NemoTextProcessing.xcframework
      perl -0pi -e 's/url:\s*"[^"]*",\s*checksum:\s*"[^"]*"/path: "Vendor-NemoTextProcessing.xcframework"/' \
        Package@swift-6.2.swift
      grep -q 'Vendor-NemoTextProcessing' Package@swift-6.2.swift
    '';

    # SwiftPM places the CLI resource bundle (Utils/english.json) beside the
    # binary and looks it up relative to the executable, so both are installed
    # together under libexec and the binary is linked into bin.
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
