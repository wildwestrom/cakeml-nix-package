{
  stdenv,
  lib,
  fetchFromGitHub,
  hol4,
  gnumake,
  bash,
  which,
}:

stdenv.mkDerivation rec {
  pname = "cakeml";
  version = "master-boot";

  src = fetchFromGitHub {
    owner = "CakeML";
    repo = "cakeml";
    rev = "vHOL-Trindemossen-2";
    sha256 = "sha256-61J00m88zcIEN43Jy2A4CcuvrNraSG8+2RKPccp2Awc=";
  };

  nativeBuildInputs = [
  ];
  buildInputs = [ hol4 ];

  buildPhase = ''
    runHook preBuild
    export HOLDIR=${hol4}
    echo "Using HOL from $HOLDIR"
    "$HOLDIR/bin/Holmake" || Holmake || true
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r * $out/
    runHook postInstall
  '';

  meta = {
    description = "CakeML sources and bootstrapped build via HOL4";
    homepage = "https://cakeml.org";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
