{
  description = "QUBIC2 biclustering algorithm";

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
      #"2.0.3" = "sha256-Vs7zovkU1DJxMGnVwoL0iDHDoezIlDKtVYDKoyKl9Ws=";
      "2019-05-17" = "sha256-jQR8pZlewQWfxbPwHSu5Jyyytug6z+nFAQ8VQ1LLXwU=";
    };
    version_revs = {
      "2019-05-17" = "5770b1d3c9e50ef41e98d9dfc2b1cb4f9ec9597a";
    };
  in rec {
    qubic2 = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "QUBIS";
        inherit version;
        src = pkgs.fetchFromGitHub {
          repo = "QUBIC2";
          owner = "OSU-BMBL";
          rev = version_revs.${version} or version;
          sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
        };
        #nativeBuildInputs = with pkgs; [zlib];
        installPhase = ''
        find .
        mkdir $out/bin -p
        cp qubic $out/bin
        '';
      });
    defaultPackage = forAllSystems (system: (qubic2.${system} "2019-05-17"));
  };
}
