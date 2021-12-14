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
            rev = "9abb5bcda16c9cb5daf1752771833e73537a3f9b";
            sha256 = "sha256-zjEV0/0L5GvspV7f8+fHRibwwrfHtT5YlBRW6VjC7i8=";
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
