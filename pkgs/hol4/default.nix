{
  lib,
  stdenv,
  pkgs,
  fetchFromGitHub,
  graphviz,
  fontconfig,
  liberation_ttf,
  experimentalKernel ? true,
}:

let
  pname = "hol4";
  vnum = "2";

  longVersion = "trindemossen-${vnum}";
  version = longVersion;
  holsubdir = "hol-${longVersion}";
  kernelFlag = if experimentalKernel then "--expk" else "--stdknl";

  polymlEnableShared =
    with pkgs;
    lib.overrideDerivation polyml (attrs: {
      configureFlags = [ "--enable-shared" ];
    });
in

stdenv.mkDerivation {
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "HOL-Theorem-Prover";
    repo = "HOL";
    rev = longVersion;
    sha256 = "sha256-esgqSlQ4M2DLNu02aALetuPJYsV/1RSEv65tEeVNno0=";
  };

  buildInputs = [
    polymlEnableShared
    graphviz
    fontconfig
    liberation_ttf
  ];

  buildCommand = ''
    mkdir chroot-fontconfig
    cat ${fontconfig.out}/etc/fonts/fonts.conf > chroot-fontconfig/fonts.conf
    sed -e 's@</fontconfig>@@' -i chroot-fontconfig/fonts.conf
    echo "<dir>${liberation_ttf}</dir>" >> chroot-fontconfig/fonts.conf
    echo "</fontconfig>" >> chroot-fontconfig/fonts.conf

    export FONTCONFIG_FILE=$(pwd)/chroot-fontconfig/fonts.conf

    mkdir -p "$out/src"
    cp -r "$src" "$out/src/${holsubdir}"
    chmod -R u+w "$out/src/${holsubdir}" || true
    cd "$out/src/${holsubdir}"

    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace "\"/bin/" "\"" \


    for f in tools/buildutils.sml help/src-sml/DOT;
    do
      substituteInPlace $f --replace "\"/usr/bin/dot\"" "\"${graphviz}/bin/dot\""
    done

    #sed -i -e "/compute/,999 d" tools/build-sequence # for testing

    export HOLDIR="$PWD/"
    poly < tools/smart-configure.sml

    # Provide wrappers expected by build system one level up from HOLDIR
    WRAPDIR="$(dirname "$PWD")"
    for WRAP in HOLlinkToSigobj ${holsubdir}linkToSigobj; do
      cat > "$WRAPDIR/$WRAP" <<'EOF'
    #!/bin/sh
    set -e
    DIR="$(dirname "$0")/${holsubdir}"
    exec "$DIR/bin/linkToSigobj" "$@"
    EOF
      chmod +x "$WRAPDIR/$WRAP"
    done

    bin/build ${kernelFlag}

    mkdir -p "$out/bin"
    ln -st $out/bin $out/src/${holsubdir}/bin/*
    # ln -s $out/src/hol4.${version}/bin $out/bin
  '';

  meta = with lib; {
    broken = (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64);
    description = "Interactive theorem prover based on Higher-Order Logic";
    longDescription = ''
      HOL4 is the latest version of the HOL interactive proof
      assistant for higher order logic: a programming environment in
      which theorems can be proved and proof tools
      implemented. Built-in decision procedures and theorem provers
      can automatically establish many simple theorems (users may have
      to prove the hard theorems themselves!) An oracle mechanism
      gives access to external programs such as SMT and BDD
      engines. HOL4 is particularly suitable as a platform for
      implementing combinations of deduction, execution and property
      checking.
    '';
    homepage = "http://hol.sourceforge.net/";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = with maintainers; [ mudri ];
  };
}
