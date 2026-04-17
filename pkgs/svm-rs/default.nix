{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.5.22";

  sources = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-k53Cg7HTNJKZzwTxotQkBnOQIpsxLaKudvhw1ehFaSY=";
    };
    x86_64-darwin = {
      triple = "x86_64-apple-darwin";
      hash = "sha256-90wYYs+RGIdsc6x2IxY3pwFZQVkK/Ih4QX3w3NYDvbg=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      hash = "sha256-rtMeJ8FNQiYABiX47W0EhSHYKIZoQLBl8nmLzi5uN6U=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      hash = "sha256-Mfaq23KVMv4DCfoeN50SblxDo98nTReVVs6YShWsF2w=";
    };
  };

  src = sources.${stdenvNoCC.hostPlatform.system} or (throw "svm-rs: unsupported platform ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "svm-rs";
    inherit version;

    src = fetchurl {
      url = "https://github.com/alloy-rs/svm-rs/releases/download/v${version}/svm-rs-${src.triple}.tar.gz";
      inherit (src) hash;
    };

    sourceRoot = "svm-rs-${src.triple}";

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 svm -t $out/bin
      runHook postInstall
    '';

    meta = with lib; {
      description = "Solidity compiler version manager (Rust)";
      homepage = "https://github.com/alloy-rs/svm-rs";
      license = licenses.asl20;
      mainProgram = "svm";
      platforms = builtins.attrNames sources;
      sourceProvenance = [sourceTypes.binaryNativeCode];
    };
  }
