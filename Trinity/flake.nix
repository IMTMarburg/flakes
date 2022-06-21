{
  description = "Trinity assembler";

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
    version_hashes = {
      #"2.7.10a" = "sha256-qwddCGMOKWgx76qGwRQXwvv9fCSeVsZbWHmlBwEqGKE=";
      "2.14.0" = "sha256-it8MaJD5ybKcIQgN7imhdMYKnjL18qcHr4a6xMn8pOo=";
    };
  in rec {
    trinity = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          name = "trinity";
          version = version;
          src = pkgs.fetchurl {
            url = "https://github.com/trinityrnaseq/trinityrnaseq/releases/download/Trinity-v${version}/trinityrnaseq-v${version}.FULL.tar.gz";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          buildPhase = ":";
          installPhase = ''
            mkdir $out/bin -p
            cp * $out/bin -r
          '';
          buildInputs = [pkgs.autoPatchelfHook pkgs.stdenv.cc.cc.lib];
        }
    );
    defaultPackage = forAllSystems (system: (trinity.${system} "2.14.0"));
  };
}
