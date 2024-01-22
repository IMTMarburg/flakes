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
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
    version_hashes = {
      "2010-09-02" = "sha256-C3qwEYEo729F3/P0VVAwohorrwFvoraAHyUxWhdjmH8=";
    };
  in rec {
    salmon = forAllSystems (
      system: version: let
        lib = pkgs.lib;
        pkgs = nixpkgsFor.${system};
      in let
        curated_regulatory_domains = {
          "hg38" = pkgs.fetchurl {
            url = "https://great-help.atlassian.net/wiki/download/attachments/655443/GREATv4.curatedRegDoms.hg38.txt?version=1&modificationDate=1627413265059&cacheVersion=1&api=v2&download=true";
            sha256 = "sha256-9jzJhv0z4Gy+8MrYxNmYt2v1E7hn943LOWF9naA19CY=";
          };

          "mm10" = pkgs.fetchurl {
            url = "https://great-help.atlassian.net/wiki/download/attachments/655443/GREATv4.curatedRegDoms.mm10.txt?version=1&modificationDate=1627413266154&cacheVersion=1&api=v2&download=true";
            sha256 = "sha256-er10QsHhJwUpyKC1utFULjN5Cli4fT27pzRUTt/UcSs=";
          };
        };
      in
        pkgs.stdenv.mkDerivation {
          pname = "GREAT";
          version = version;
          src = pkgs.fetchzip {
            url = "http://bejerano.stanford.edu/resources/greatTools.tar.gz";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          postPatch = ''
            substituteInPlace makefile --replace "path/to/your/kent/src" "${pkgs.kent}" \
              --replace "\$(KENT_DIR)/lib/\$(MACHTYPE)/jkweb.a" "${pkgs.kent}/lib/jkweb.a" \
              --replace "LDFLAGS=" "LDFLAGS=-L${pkgs.openssl.out}/lib" \
              --replace "-lm" "-lm -lssl -lcrypto -lhts"
              cat makefile
          '';
          nativeBuildInputs = [pkgs.kent pkgs.htslib pkgs.openssl.dev];
          installPhase =
            ''
              mkdir $out/bin -p
              cp calculateBinomialP $out/bin
              cp createRegulatoryDomains $out/bin

              mkdir $out/curated_regulatory_regions
            ''
            + (builtins.concatStringsSep "\n" (
              lib.mapAttrsToList (name: url_pkg: ''
                cp ${url_pkg} $out/curated_regulatory_regions/${name}.tsv
              '')
              curated_regulatory_domains
            ));
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
