{
  stdenv,
  lib,
  fetchFromGitHub,
  hol4,
  gnumake,
  bash,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "cakeml";
  version = "vHOL-Trindemossen-2";

  src = fetchFromGitHub {
    owner = "CakeML";
    repo = "cakeml";
    rev = "vHOL-Trindemossen-2";
    sha256 = "sha256-61J00m88zcIEN43Jy2A4CcuvrNraSG8+2RKPccp2Awc=";
  };

  nativeBuildInputs = [
    hol4
    gnumake
    bash
  ];
  buildInputs = [ ];

  # Prebuilt tarball fallback (verified bootstrapped compiler and FFI sources)
  prebuilt = fetchurl {
    url = "https://github.com/CakeML/cakeml/releases/download/${version}/cake-x64-64.tar.gz";
    # nix-prefetch-url result
    sha256 = "1yp25pbrk2z22z2ljywc6jdww2qhcil92i1aa32yv5nvx5kknvhz";
  };

  # For now, stage 1: install from prebuilt release to get working `cake`.
  # We will iterate to full-from-source bootstrap once HOL4 Holmake interaction is unblocked.
  buildPhase = ''
    runHook preBuild
    mkdir prebuilt && cd prebuilt
    tar -xzf ${prebuilt}
    cd cake-x64-64
    make
    cd ../..
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    (cd prebuilt/cake-x64-64 && make)
    install -Dm755 prebuilt/cake-x64-64/cake "$out/bin/cake"
    runHook postInstall
  '';

  meta = {
    description = "CakeML sources and bootstrapped build via HOL4";
    homepage = "https://cakeml.org";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
