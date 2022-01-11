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

    in rec {
      defaultPackage = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "DMAP";
          version = "2021-05-27";
          src = pkgs.fetchFromGitHub {
            repo = "DMAP";
            owner = "peterstockwell";
            rev = "6d1ab2f1405818baf7b225a075d203c16937f26a";
            sha256 = "sha256-Z7xFZRmKgW7G48nMhForRZo03MmG0NxKTmlzzVUYhgM=";
          };
          nativeBuildInputs = with pkgs; [ zlib ];
          buildPhase = ''
            cd src
            make
          '';
          installPhase = ''
            mkdir $out
            exeFiles=()
            for f in "./"/*; do [[ -x $f && -f $f ]] && exeFiles+=( "$f" ); done
            cp "''${exeFiles[@]}" "$out/"
          '';
        });
    };
}
