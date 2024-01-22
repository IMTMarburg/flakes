{
  description = "GREAT ChipSeq overlap analysis";

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
      "2010-09-02" = "sha256-C3qwEYEo729F3/P0VVAwohorrwFvoraAHyUxWhdjmH8=";
    };
  in rec {
    salmon = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          pname = "GREAT";
          version = version;
          src = pkgs.fetchzip {
            url = "http://bejerano.stanford.edu/resources/greatTools.tar.gz";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          postPatch= ''
          substituteInPlace makefile --replace "path/to/your/kent/src" "${pkgs.kent}" \
            --replace "\$(KENT_DIR)/lib/\$(MACHTYPE)/jkweb.a" "${pkgs.kent}/lib/jkweb.a" \
            --replace "LDFLAGS=" "LDFLAGS=-L${pkgs.openssl.out}/lib" \
            --replace "-lm" "-lm -lssl -lcrypto -lhts"
            cat makefile
          '';
          nativeBuildInputs = [pkgs.kent pkgs.htslib pkgs.openssl.dev];
          installPhase = ''
            mkdir $out/bin -p
            cp calculateBinomialP $out/bin
            cp createRegulatoryDomains $out/bin
          '';
          meta = {
            description = "GREAT ChipSeq overlap analysis";
            homepage = "https://great-help.atlassian.net/wiki/spaces/GREAT/pages/655416/Download";
            #license = pkgs.lib.licenses.bsd3;
            platforms = supportedSystems;
          };
        }
    );
    defaultPackage = forAllSystems (system: (salmon.${system} "2010-09-02"));
  };
}
