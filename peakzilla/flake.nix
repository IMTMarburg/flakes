{
  description = "flake for peakzilla";
  # why don't we just add it to the python packages?
  # because we want it to be independent of our python packages / python version
  # (e.g. MACS2 2.2.7.1 is (trivially) not python 3.10 compatible,
  # because they cast the version to a float and compare to <3.6 

  inputs = { nixpkgs.url = "nixpkgs/nixos-21.05"; };

  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {
      defaultPackage = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          pyenv = pkgs.python38.withPackages (p: with p; [ pysam ]);
        in pkgs.stdenv.mkDerivation {
          pname = "peakzilla";
          version = "2017-05-06"; # must match your git hash
          src = pkgs.fetchFromGitHub {
            owner = "IMTMarburg";
            repo = "peakzilla";
            rev = "683cd640c81f3aeb622945026c36f11072ba6ea7";
            sha256 = "sha256-QbwOPRkC3e7A3jvHqmGOGnIcsdEu2pHUL/+zXgDNKGY=";
          };
          nativeBuildInputs = [ pyenv ];
          buildPhase = ":";
          installPhase = ''
            mkdir -p $out/bin
            cp peakzilla.py $out/bin
            chmod +x $out/bin/peakzilla.py
            patchShebangs $out/bin/peakzilla.py
          '';
        });
    };
}
