{
  description = "StringTie RNAseq assembler";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # doesn't matter much

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ]; # it's java afterall
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {

      # package.
      defaultPackage = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "StringTie";
          version = "2.0.3";
          src = pkgs.fetchurl {
            url =
              "http://ccb.jhu.edu/software/stringtie/dl/stringtie-2.2.0.tar.gz";
            sha256 = pkgs.lib.fakeSha256;
          };
          nativeBuildInputs = [];
          buildPhase = ''
            make release
          '';
          installPhase = ''
          mkdir $out/bin -p
          cp ../bin/* $out/bin/
          '';
        });
    };
}
