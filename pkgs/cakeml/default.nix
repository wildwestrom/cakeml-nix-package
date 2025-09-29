{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  gnumake,
  gcc,
  coreutils,
  hol4,
  polyml,
}:

stdenv.mkDerivation {
  pname = "cakeml";
  version = "vHOL-Trindemossen-2";

  src = fetchFromGitHub {
    owner = "CakeML";
    repo = "cakeml";
    rev = "vHOL-Trindemossen-2";
    sha256 = "sha256-61J00m88zcIEN43Jy2A4CcuvrNraSG8+2RKPccp2Awc=";
  };

  nativeBuildInputs = [
    gnumake
    gcc
    makeWrapper
    polyml
    hol4
  ];
  buildInputs = [ coreutils ];

  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR"
    export PATH=${hol4}/bin:$PATH
    chmod -R u+w .
    # Prepare a writable HOL4 source tree for Holmake
    cp -r ${hol4}/src/hol-* ./hol4-src
    chmod -R u+w ./hol4-src
    export HOLDIR="$PWD/hol4-src"
    # Ensure a writable Holmake work dir in CakeML tree
    rm -rf .hol || true
    mkdir -p .hol/make-deps
    # Build CakeML using HOL4; this can take a long time
    ${hol4}/bin/Holmake
    cd compiler/bootstrap/compilation/x64
    make -j${stdenv.hostPlatform.parallellism or "1"} cake
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -Dm755 compiler/bootstrap/compilation/x64/cake "$out/bin/cake"
    runHook postInstall
  '';

  meta = {
    description = "CakeML sources and bootstrapped build via HOL4";
    homepage = "https://cakeml.org";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
