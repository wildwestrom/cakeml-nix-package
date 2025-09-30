{
  description = "CakeML toolchain bootstrap from source";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          hol4 = pkgs.callPackage ./pkgs/hol4 { };
          cakeml = pkgs.callPackage ./pkgs/cakeml { hol4 = hol4; };
          default = self.packages.${system}.cakeml;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            gnumake
            pkg-config
            bash
            curl
            cacert
            which
            # build deps we likely need for Poly/ML and HOL
            perl
            python3
            rsync
            zlib
            gmp
            ncurses
          ];
        };
      }
    );
}
