{
  description = "Genmap provides ultra fast mapabillity calculation for genomes";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";
  # this line assume that you also have nixpkgs as an input

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
      ]; # "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ]; guess we could adjust the url...
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {

      # package.
      defaultPackage = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "genmap";
          version = "1.3.0";
          src = pkgs.fetchzip {
            url =
              "https://github.com/cpockrandt/genmap/releases/download/genmap-v1.3.0/genmap-1.3.0-Linux-x86_64-sse4.zip";
              sha256 = "sha256-ZQJLZNl09wToFcjgS8vBkI0f8mJ/tBRTQIMm9tku4iU=";
          };
          #autoPatchelfIgnoreMissingDeps=true; # libidn.11 - but nixpkgs has .12
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            zlib
            libgccjit
                    ];
          buildPhase = "";
          installPhase = ''
            mkdir $out/bin -p
            cp genmap $out/bin
          '';
        });
    };
}
