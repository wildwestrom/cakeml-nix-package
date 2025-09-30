{
  stdenv,
  lib,
  fetchurl,
  gnumake,
  bash,
  hol4
}:

stdenv.mkDerivation rec {
  pname = "cakeml";
  version = "vHOL-Trindemossen-2";

  # src = fetchFromGitHub {
  #   owner = "CakeML";
  #   repo = "cakeml";
  #   rev = "vHOL-Trindemossen-2";
  #   sha256 = "sha256-61J00m88zcIEN43Jy2A4CcuvrNraSG8+2RKPccp2Awc=";
  # };

  # Use the verified release tarball that contains pre-generated cake.S
  src = fetchurl {
    url = "https://github.com/CakeML/cakeml/releases/download/${version}/cake-x64-64.tar.gz";
    sha256 = "sha256-H247Z+nblu3FUCpEkWhkEAvOmzSMe0nFF+KLmdct4vo=";
  };

  nativeBuildInputs = [
    gnumake
    bash
    stdenv
    hol4
  ];
  buildInputs = [ ];

  enableParallelBuilding = true;

  # Set environment variables that might be needed
  preBuild = ''
    export CML_STACK_SIZE=1000
    export CML_HEAP_SIZE=6000
  '';

  buildPhase = ''
    runHook preBuild\
    echo "Building CakeML compiler from release sources..."
    if [ -d cake-x64-64 ]; then
      cd cake-x64-64
    fi
    make cake
    runHook postBuild
  '';

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    mkdir -p "$out/share/cakeml"

    # Install the main CakeML tools
    if [ -f "cake" ]; then
      install -Dm755 cake "$out/bin/cake"
    elif [ -f "compiler/bootstrap/compilation/x64/cake" ]; then
      install -Dm755 compiler/bootstrap/compilation/x64/cake "$out/bin/cake"
    fi

    # Install FFI sources needed to build user programs
    if [ -f "basis_ffi.c" ]; then
      install -Dm644 basis_ffi.c "$out/share/cakeml/basis_ffi.c"
    elif [ -f "compiler/bootstrap/compilation/x64/basis_ffi.c" ]; then
      install -Dm644 compiler/bootstrap/compilation/x64/basis_ffi.c "$out/share/cakeml/basis_ffi.c"
    fi

    # Install the source code and documentation (lightweight)
    cp -r README.md howto "$out/share/cakeml/" 2>/dev/null || true

    runHook postInstall
  '';

  installCheckPhase = ''
    # Verify the compiler runs and can build a trivial program
    if [ ! -x "$out/bin/cake" ]; then
      echo "No CakeML compiler found in $out/bin/"
      ls -la "$out/bin/"
      exit 1
    fi
    echo 'print "Hello, World!\\n";' > hello.cml
    "$out/bin/cake" < hello.cml > hello.cake.S
    cc hello.cake.S "$out/share/cakeml/basis_ffi.c" -lm -o hello.cake
    ./hello.cake | grep -q "Hello, World!"
  '';

  meta = {
    description = "CakeML sources and bootstrapped build via HOL4";
    homepage = "https://cakeml.org";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
