{
  description = "RADMeth - regression Analysis of Differential Methylation";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.11"; # doesn't matter much

  outputs =
    { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
        # "x86_64-darwin"
        # "aarch64-linux"
        # "aarch64-darwin"
      ]; # it's java afterall
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      version_hashes = {
        "cddde32d3a3e1a54fab5babbc9675a536382af26" = "sha256-baJ+PfLNYdpdDfMvhb7jSaWty21DRU7vYmEebJtMANk=";
      };

    in
    rec {
      radmeth = forAllSystems (
        system: version:
        let
          pkgs = nixpkgsFor.${system};
        in
        pkgs.stdenv.mkDerivation rec {
          pname = "radmeth";
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "smithlabcode";
            repo = "radmeth";
            rev = version;
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
            fetchSubmodules = true;
          };
          nativeBuildInputs = with pkgs; [ gsl ];
            installPhase = ''
              mkdir -p $out/bin
              cp bin/* $out/bin/
            '';
        }
      );
      defaultPackage = forAllSystems (
        system: (radmeth.${system} "cddde32d3a3e1a54fab5babbc9675a536382af26")
      );
    };
}
