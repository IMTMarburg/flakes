{
  description = "GRIDSS - the Genomic Rearrangement IDentification Software Suite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Date-pinned CRAN/Bioconductor. Deliberately does *not* follow nixpkgs:
    # nixR brings the nixpkgs matching its R/Bioconductor snapshot.
    nixR.url = "github:TyberiusPrime/nixR";
    gridss-src = {
      url = "github:PapenfussLab/gridss/v2.13.2";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixR,
      gridss-src,
    }:
    let
      # nixR only supports x86_64-linux.
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      version = "2.13.2";

      # Last day of Bioconductor 3.14 (R 4.1.3) - the release that was current
      # when GRIDSS 2.13.2 came out (2022-02-07).
      rDate = "2022-04-26";

      # R packages required by the GRIDSS R scripts
      # (gridss_somatic_filter, libgridss.R, gridss.config.R,
      # gridss_extract_overlapping_fragments' VCF->BED conversion, virusbreakend)
      # plus the general set installed by upstream's Dockerfile.
      defaultRPackages = [
        "argparser"
        "assertthat"
        "testthat"
        "tidyverse"
        "readr"
        "stringr"
        "stringdist"
        "ggplot2"
        "matrixStats"
        "randomForest"
        "R.cache"
        "Rcpp"
        "blob"
        "RSQLite"
        "Biobase"
        "BiocGenerics"
        "S4Vectors"
        "IRanges"
        "XVector"
        "Biostrings"
        "DelayedArray"
        "BSgenome"
        "Rsamtools"
        "rtracklayer"
        "VariantAnnotation"
        "StructuralVariantAnnotation"
        "copynumber"
      ];

      mkGridss =
        pkgs:
        {
          # e.g. [ "BSgenome.Hsapiens.UCSC.hg38" ] for gridss_somatic_filter --ref
          extraRPackages ? [ ],
        }:
        let
          lib = pkgs.lib;

          gridssR = nixR.R_by_date {
            date = rDate;
            r_pkg_names = defaultRPackages ++ extraRPackages;
          };

          jar = pkgs.fetchurl {
            url = "https://github.com/PapenfussLab/gridss/releases/download/v${version}/gridss-${version}-gridss-jar-with-dependencies.jar";
            hash = "sha256-TRcfkHNC6Xd89qUFRYriqPIWJPe82R0pukjxodJU72k=";
          };

          # gridsstools builds against a pinned htslib git submodule (which in
          # turn has the htscodecs submodule) - flake inputs don't fetch those.
          htslib-src = pkgs.fetchFromGitHub {
            owner = "samtools";
            repo = "htslib";
            rev = "c37e0413d42b47328c94a5f21814526de5d2312e";
            fetchSubmodules = true;
            hash = "sha256-yBsdH0b3h9bPo3P8oUM/BRmEWQaFag7f1mWjK/Dw+fc=";
          };

          gridsstools = pkgs.stdenv.mkDerivation {
            pname = "gridsstools";
            inherit version;

            src = gridss-src;

            nativeBuildInputs = [
              pkgs.autoreconfHook
              pkgs.perl
            ];
            buildInputs = [
              pkgs.zlib
              pkgs.bzip2
              pkgs.xz
              pkgs.curl
              pkgs.openssl
              pkgs.libdeflate
            ];

            sourceRoot = "source/src/main/c/gridsstools";

            postUnpack = ''
              rmdir source/src/main/c/gridsstools/htslib
              cp -r ${htslib-src} source/src/main/c/gridsstools/htslib
              chmod -R u+w source/src/main/c/gridsstools/htslib
              # Normally generated from `git describe`; there's no .git here.
              echo '#define HTSCODECS_VERSION_TEXT "1.1.1"' \
                > source/src/main/c/gridsstools/htslib/htscodecs/htscodecs/version.h
            '';

            # The bundled htslib has to be configured first, and
            # htslib_static.mk (included by gridsstools' Makefile) generated.
            preConfigure = ''
              (cd htslib && autoreconf -i && ./configure && make htslib_static.mk)
            '';

            # `all` also runs the test suite against src/test/resources.
            buildFlags = [ "all" ];
            enableParallelBuilding = false;

            installPhase = ''
              runHook preInstall
              install -Dm755 gridsstools $out/bin/gridsstools
              runHook postInstall
            '';

            meta = {
              description = "GRIDSS helper utilities (fragment extraction)";
              homepage = "https://github.com/PapenfussLab/gridss";
              license = lib.licenses.gpl3Only;
              mainProgram = "gridsstools";
              platforms = [ "x86_64-linux" ];
            };
          };

          # Tools the scripts look for via `which`. kraken2 and RepeatMasker
          # (needed by virusbreakend / gridss_annotate_vcf_*) are not in nixpkgs
          # and have to be provided by the user's PATH.
          runtimePath = lib.makeBinPath [
            pkgs.jdk11_headless
            gridssR
            gridsstools
            pkgs.samtools
            pkgs.bcftools
            pkgs.bwa
            pkgs.bedtools
            pkgs.hmmer
            pkgs.blast
            pkgs.trf
            pkgs.util-linux # getopt
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
            pkgs.gnutar
            pkgs.gzip
            pkgs.which
            pkgs.time
            pkgs.rsync
            pkgs.wget
          ];

          shellScripts = [
            "gridss"
            "gridss_annotate_vcf_kraken2"
            "gridss_annotate_vcf_repeatmasker"
            "gridss_extract_overlapping_fragments"
            "virusbreakend"
            "virusbreakend-build"
          ];
        in
        pkgs.stdenv.mkDerivation {
          pname = "gridss";
          inherit version;

          src = gridss-src;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = [
            pkgs.bash
            gridssR
          ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            share=$out/share/gridss
            mkdir -p $share $out/bin

            install -Dm644 ${jar} $share/gridss.jar
            install -m644 scripts/libgridss.R scripts/gridss.config.R $share/
            install -m755 scripts/gridss_somatic_filter ${lib.concatStringsSep " " (map (s: "scripts/${s}") shellScripts)} $share/

            # Upstream defaults --scriptdir to the script *file* rather than
            # its directory, so libgridss.R is never found without --scriptdir.
            substituteInPlace $share/gridss_somatic_filter \
              --replace-fail 'default=thisFile()' "default=\"$share\""

            # Prefer the real GNU time over the bash builtin when timing steps.
            for s in gridss; do
              substituteInPlace $share/$s --replace-quiet /usr/bin/time ${pkgs.time}/bin/time
            done

            patchShebangs $share

            for s in gridss_somatic_filter ${lib.concatStringsSep " " shellScripts}; do
              makeWrapper $share/$s $out/bin/$s \
                --prefix PATH : $out/bin:${runtimePath} \
                --set-default GRIDSS_JAR $share/gridss.jar
            done

            # Direct access to the jar's tools, e.g. `gridss-java gridss.CallVariants ...`
            makeWrapper ${pkgs.jdk11_headless}/bin/java $out/bin/gridss-java \
              --prefix PATH : ${runtimePath} \
              --add-flags "-cp $share/gridss.jar"

            ln -s ${gridsstools}/bin/gridsstools $out/bin/gridsstools

            runHook postInstall
          '';

          passthru = {
            inherit gridsstools gridssR jar;
          };

          meta = {
            description = "Genomic Rearrangement IDentification Software Suite";
            homepage = "https://github.com/PapenfussLab/gridss";
            license = lib.licenses.gpl3Only;
            mainProgram = "gridss";
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      lib.mkGridss = mkGridss;

      packages = forAllSystems (
        pkgs:
        let
          gridss = mkGridss pkgs { };
        in
        {
          inherit gridss;
          inherit (gridss) gridsstools gridssR;
          default = gridss;
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.gridss ];
        };
      });
    };
}
