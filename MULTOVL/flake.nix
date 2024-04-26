{
  description = "Multiple Overlap of Genomic Regions";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11"; # doesn't matter much

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
    version_hashes = {
      #"1.9.0" = "sha256-gk/gnXIPEL6luEzwIBhZG75gTJHh9AGYYOl8Qz78pac=";
    };
    };
  in rec {
    salmon = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          pname = "multovl";
          version = version;
          src = pkgs.fetchFromGitHub {
            owner = "aaszodi";
            repo = "multovl";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          nativeBuildInputs = [pkgs.cmake pkgs.boost];
          installPhase = ''
            mkdir $out -p
            ls -la
            aoeu
            cp $src/* $out -r
          '';
        }
    );
    defaultPackage = forAllSystems (system: (salmon.${system} "1.3-zenodo"));
  };
}
