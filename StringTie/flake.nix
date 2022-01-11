{
  description = "StringTie RNAseq assembler";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.11"; # we need htslib > 1.11

  outputs = { self, nixpkgs }:
    let

      # Generate aa user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ]; # it's java afterall
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      version_hashes = {
        "2.0.3" = "sha256-FSyZ4qxczIPP8+pVo8hjcVFZarQhWhehG7Nq1HW9S0I=";
        "2.0.6" = "sha256-Mi1cv2r4HjBjJmaIBk0rlipLsUrbWCPvVQN22R1v+R0=";
        "2.2.0" = "sha256-fUQ1FDrfH+n2Bs5jU0ORRvWIIo9ozHOZSm4mT6COgyM=";
      };

    in rec {

      # package.
      stringtie = forAllSystems (system: version:
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "StringTie";
          inherit version;
          src = pkgs.fetchurl {
            url =
              "http://ccb.jhu.edu/software/stringtie/dl/stringtie-${version}.tar.gz";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          nativeBuildInputs = with pkgs; [
            zlib
            htslib
            bzip2
            libdeflate
            xz
            curl.dev
            openssl.dev
          ];
          patches = [ ./patch-2.2.0.patch ];
          buildPhase = ''
            set -euo pipefail
              export HTSLIB=${pkgs.htslib}/lib;
              export LIBDEFLATE=${pkgs.libdeflate}/lib/libdeflate.a;
              export LIBBZ2=-lbz2;
              export LIBLZMA=-llzma;
              make release
          '';
          installPhase = ''
            mkdir $out/bin -p
            cp stringtie $out/bin/
          '';
        });
      defaultPackage = forAllSystems (system: (stringtie.${system} "2.2.0"));

    };
}
