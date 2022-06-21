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
      "3.15.4" = "sha256-+kHFCJPJwbPsnJpQh/aXcPod+I/YX9s148PQVyoD6og=";
    };
  in rec {
    SPAdes = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          name = "spades";
          version = version;
          src = pkgs.fetchurl {
            url = "https://cab.spbu.ru/files/release3.15.4/SPAdes-3.15.4-Linux.tar.gz";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          buildPhase = ":";
          installPhase = ''
            mkdir $out -p
            cp * $out -r
          '';
          buildInputs = [pkgs.autoPatchelfHook];
        }
    );
    defaultPackage = forAllSystems (system: (SPAdes.${system} "3.15.4"));
  };
}
