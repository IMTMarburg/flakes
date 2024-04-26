{
  description = "noise-suppression-for-voice ";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    # Generate a user-friendly version number.
    #version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
    ]; # it's java afterall
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    version_hashes = {
      #"1.03" = "sha256-Vs7zovkU1DJxMGnVwoL0iDHDoezIlDKtVYDKoyKl9Ws=";
    };
  in rec {
    mypackage = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "noise-suppression-for-voice";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "werman";
          repo = "noise-suppression-for-voice";
          sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
        };
        #nativeBuildInputs = with pkgs; [ zlib ];
      });
    defaultPackage = forAllSystems (system: (mypackage.${system} "2.0.3"));
  };
}
