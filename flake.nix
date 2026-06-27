{
  description = "CakeML toolchain bootstrap from source. Special thanks to Liam Murphy (@Liamolucko) for the CakeML derivation.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      overlay = final: prev: {
        # A pinned x86_64-linux package set (carrying this same overlay) so the
        # bootstrap can always reach a native x64 cakeml to run stage-0/stage-1,
        # regardless of the host platform we're ultimately building for.
        pkgsx86_64Linux = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ overlay ];
        };

        hol4 = final.callPackage ./pkgs/hol4 { };
        cakeml = final.callPackage ./pkgs/cakeml { };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = rec {
          inherit (pkgs) hol4 cakeml;
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
