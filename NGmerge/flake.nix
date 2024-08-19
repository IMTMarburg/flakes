{
  description = "Subread aligner";

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
      "v0.3" = "sha256-yuk5WP8B3itEQ5djS1FWNEpiXq1UbUWFMgFtwBqdgPI=";
    };
  in rec {
    ngmerge = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "SNGMerge";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "jsh58";
          repo = "NGMerge";
          rev = version;
          sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
        };
        nativeBuildInputs = with pkgs; [zlib mpi];
        installPhase = ''
        mkdir $out/bin -p 
        cp NGmerge $out/bin
        '';
      });
    defaultPackage = forAllSystems (system: (ngmerge.${system} "v0.3"));
  };
}
