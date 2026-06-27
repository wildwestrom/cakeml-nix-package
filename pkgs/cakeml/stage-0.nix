{
  stdenv,
  fetchFromGitHub,
  hol4,
  arch,
  bits,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cakeml-stage-0";
  version = "HOL-Trindemossen-2";

  src = fetchFromGitHub {
    owner = "CakeML";
    repo = "cakeml";
    tag = "v${finalAttrs.version}";
    hash = "sha256-61J00m88zcIEN43Jy2A4CcuvrNraSG8+2RKPccp2Awc=";
  };

  nativeBuildInputs = [ (hol4.override { experimentalKernel = false; }) ];

  buildPhase = ''
    runHook preBuild

    cd compiler/bootstrap/compilation/${arch}/${bits}
    Holmake cake-${arch}-${bits}.tar.gz -j "$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir "$out"
    tar -xf cake-${arch}-${bits}.tar.gz -C "$out" --strip-components 1

    runHook postInstall
  '';
})