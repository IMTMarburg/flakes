{
  description = "seqstats";

  inputs.nixpkgs.url = "nixpkgs/nixos-24.05"; # doesn't matter much

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
      "e6f482ff1f6069837958a5b31aaca3ba95e3db88" = "sha256-/iUTyovJo6S6H7B8XsVTP0fiB7yj6LA04igKA3yk2dM=";
    };
  in rec {
    seqstats = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "seqstats";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "clwgg";
          repo = "seqstats";
          rev = version;
          sha256 = version_hashes.${version};
          fetchSubmodules = true;
        };
        nativeBuildInputs = with pkgs; [zlib];
        installPhase = ''
        ls -la
        find .
          mkdir $out/bin -p
          cp ./seqstats $out/bin/ 
        '';
      });
    defaultPackage = forAllSystems (system: (seqstats.${system} "e6f482ff1f6069837958a5b31aaca3ba95e3db88"));
  };
}
