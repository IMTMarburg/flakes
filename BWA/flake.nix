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
          pname = "BWA";
          version = "0.7.17";
          src = pkgs.fetchurl {
            url =
              "mirror://sourceforge/bio-bwa/bwa-0.7.17.tar.bz2";
            sha256 = "sha256-3htNTnRcC3/D4Qe1FVpRrAYwEdM6XYJpYzHs9L7Y0P0=";
          };
          nativeBuildInputs = with pkgs; [zlib];
          installPhase = ''
          mkdir $out/bin -p 
          cp bwa $out/bin 
          '';
        });
    };
}
