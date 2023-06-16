{
  description = "Bowtie aligner";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    # Generate a user-friendly version number.
    #version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ]; # it's java afterall
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    # package.
    defaultPackage = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        piper-phonemize = pkgs.stdenv.mkDerivation rec {
          pname = "piper-phonemize";
          version = "1.0.0";
          src = pkgs.fetchFromGithub {
            owner = "rhasspy";
            repo = "piper-phonemize";
            rev = "47d53b6d15419432441d16078b4e0f2df233d965";
          };
        };
        piper = pkgs.stdenv.mkDerivation rec {
          pname = "piper";
          version = "1.0.0";
          src = pkgs.fetchFromGithub {
            owner = "rhasspy";
            repo = "piper";
            rev = "3f5d3b56a89fa2729badfba679a72e392f8a4c02";
          };
        };
      in
        piper-phonemize
    );
  };
}
