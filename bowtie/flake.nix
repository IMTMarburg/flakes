{
  description = "Bowtie aligner";

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
          pname = "bowtie";
          version = "1.3.1";
          src = pkgs.fetchzip {
            url =
              "mirror://sourceforge/bowtie-bio/bowtie/${version}/bowtie-${version}-src.zip";
            sha256 = "sha256-n3JtVGqfa9KGaspuDbUhfayopYsbqy4ifJnAVlpBZ5E=";
          };
          nativeBuildInputs = with pkgs; [zlib];
          installPhase = ''
          mkdir $out/bin -p 
          ls -la
          cp bowtie-build-s $out/bin/
          cp bowtie-build-l $out/bin/
          cp bowtie-align-s $out/bin/
          cp bowtie-align-l $out/bin/
          cp bowtie-inspect-s $out/bin/
          cp bowtie-inspect-l $out/bin/
          cp bowtie-inspect $out/bin/
          cp bowtie-build $out/bin/
          cp bowtie $out/bin/
          '';
        });
    };
}
