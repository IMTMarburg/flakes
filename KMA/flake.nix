{
  description = "KMA quantifier against repetitive databases";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.05"; # doesn't matter much

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
        #"x86_64-darwin"
        #"aarch64-linux"
        #"aarch64-darwin"
      ]; # it's java afterall
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      version_hashes = {
        "1.4.14" = "sha256-OMuPSEg/7hQEp2zqOB1rm7cCaNv6VgMSnXQHNppdV3U="; # kma -v reported version...
        #"2.0.3" = "sha256-Vs7zovkU1DJxMGnVwoL0iDHDoezIlDKtVYDKoyKl9Ws=";
      };

    in rec {
      subread = forAllSystems (system: version:
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "KMA";
          inherit version;
          src = pkgs.fetchgit {
            url =
              "https://bitbucket.org/genomicepidemiology/kma.git";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
            rev = version;
          };
          nativeBuildInputs = with pkgs; [ zlib ];
          #sourceRoot = "subread-${version}-source/src";
          installPhase = ''
          ls -la
            mkdir $out/bin -p
            cp kma $out/bin/ || true
          '';
        });
      defaultPackage = forAllSystems (system: (subread.${system} "1.4.14"));
    };
}
