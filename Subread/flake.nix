{
  description = "Subread aligner";

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
          pname = "Subread";
          version = "2.0.3";
          src = pkgs.fetchurl {
            url =
              "mirror://sourceforge/subread/subread-2.0.3/subread-2.0.3-source.tar.gz";
            sha256 = "sha256-Vs7zovkU1DJxMGnVwoL0iDHDoezIlDKtVYDKoyKl9Ws=";
          };
          nativeBuildInputs = with pkgs; [zlib ];
          sourceRoot = "subread-${version}-source/src";
          buildPhase = ''
            make -f Makefile.Linux
          '';
          installPhase = ''
          mkdir $out/bin -p
          cp ../bin/* $out/bin/ || true
          '';
        });
    };
}
