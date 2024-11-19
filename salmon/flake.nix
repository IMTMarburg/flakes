{
  description = "salmon read quantifie ";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    # Generate a user-friendly version number.
    #version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
      # "x86_64-darwin"
      # "aarch64-linux"
      # "aarch64-darwin"
    ]; #
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    salmon_version_hashes = {
      "1.9.0" = "sha256-gk/gnXIPEL6luEzwIBhZG75gTJHh9AGYYOl8Qz78pac=";
      "1.10.0" = "sha256-Qtzeo1dO6g0a5qvUK8jcELT3EoOnpNY5Wj6e1/AVoPo=";

    };
    pufferfish_version_hashes = {
    };
  in rec {
    salmon = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          pname = "salmon";
          version = version;
          src = pkgs.fetchzip {
            url = "https://github.com/COMBINE-lab/salmon/releases/download/v${version}/salmon-${version}_linux_x86_64.tar.gz";
            sha256 = salmon_version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          nativeBuildInputs = [pkgs.autoPatchelfHook];
          buildPhase = ":";
          installPhase = ''
            mkdir $out -p
            cp $src/* $out -r
          '';
        }
    );
    #$ building from source necessitates replicating and patching the pufferfish fetch script
    # (because everybody has their own weird little package manager...)
    #     pkgs.stdenv.mkDerivation {
    #       pname = "salmon";
    #       inherit version;
    #       src = pkgs.fetchFromGitHub {
    #         owner = "COMBINE-lab";
    #         repo = "salmon";
    #         rev = "v" + version;
    #         sha256 = salmon_version_hashes.${version} or pkgs.lib.fakeSha256;
    #       };
    #       pufferfish = pkgs.fetchFromGitHub pkgs.fetchFromGitHub {
    #         owner = "COMBINE-lab";
    #         repo = "pufferfish";
    #         rev = "salmonv" + version;
    #         sha256 = puffer_fish_version_hashes.${version} or pkgs.lib.fakeSha256;
    #       };
    #       nativeBuildInputs = with pkgs; [
    #         cmake
    #       ];
    #       # buildPhase = ''
    #       #   set -euo pipefail
    #       #     export HTSLIB=${pkgs.htslib}/lib;
    #       #     export LIBDEFLATE=${pkgs.libdeflate}/lib/libdeflate.a;
    #       #     export LIBBZ2=-lbz2;
    #       #     export LIBLZMA=-llzma;
    #       #     make release
    #       # '';
    #       # installPhase = ''
    #       #   mkdir $out/bin -p
    #       #   cp stringtie $out/bin/
    #       # '';
    #     }
    # );
    defaultPackage = forAllSystems (system: (salmon.${system} "1.10.0"));
  };
}
