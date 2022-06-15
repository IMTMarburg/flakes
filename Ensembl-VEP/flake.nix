{
  description = "Bowtie aligner";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

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
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg:
            builtins.elem (pkg.pname) [
              "kent"
            ];
        };
      });
  in {
    # package.
    defaultPackage = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};

      TestWeaken = pkgs.perl534Packages.buildPerlPackage {
        pname = "Test-Weaken";
        version = "3.022000";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/K/KR/KRYDE/Test-Weaken-3.022000.tar.gz";
          sha256 = "2631a87121310262e0e96107a6fa0ed69487b7701520773bee5fa9accc295f5b";
        };
        meta = {
          description = "Test that freed memory objects were, indeed, freed";
          license = with pkgs.lib.licenses; [artistic1 gpl1Plus];
        };
      };
      kent_with_source = pkgs.kent.overrideAttrs (old: {
        version = "375";
        src = pkgs.fetchFromGitHub {
          owner = "ucscGenomeBrowser";
          repo = "kent";
          rev = "0a8766dc9b50da2cca3ee86fdb02c95bb7e9893e";
          sha256 = "sha256-QFLTximWjmujHqw94tXytPQ9ssN/vFPa3gEKq1tjucI=";
        };

        installPhase =
          old.installPhase
          + ''
            mkdir -p $out/src
            echo 'build'
            ls /build
            echo 'build/source'
            ls /build/source
            cp /build/source/src/* $out/src -r
            mkdir $out/src/lib/ -p
            ln -s -t $out/src/lib $out/lib/jkweb.a
          '';
      });

      BioBigFile = pkgs.perl534Packages.buildPerlModule {
        pname = "Bio-BigFile";
        version = "1.07";
        # src = fetchurl {
        #   url = "mirror://cpan/authors/id/L/LD/LDS/Bio-BigFile-1.07.tar.gz";
        #   sha256 =
        #     "277b66ce8acbdd52399e2c5a0cf4e3bd5c74c12b94877cd383d0c4c97740d16d";
        # };
        src =
          pkgs.fetchFromGitHub {
            owner = "GMOD";
            repo = "GBrowse-Adaptors";
            rev = "85c29de2f29b89d60af552d0cfd54f96f55fbc31";
            sha256 = "sha256-WdPZBYZa6MdzKVHIwz2iQhG2U+NfREvG24EXWySqdPo=";
          }
          + "/Bio-BigFile";

        KENT_SRC = "${kent_with_source}/src";
        buildInputs = [kent_with_source pkgs.zlib pkgs.openssl];
        # nativeBuildInputs = [ breakpointHook ];
        propagatedBuildInputs = [BioPerl pkgs.perl534Packages.IOString];
        postPatch = ''
          substituteInPlace Build.PL \
          --replace "'-pthread'" "'-lpthread'," \
          --replace "'-Wformat=0'," "'-Wformat=0', '-Wno-format-security', '-pthread', " \

          export MACHTYPE=$(uname -m) # so we can find jkweb.a.
        '';
        # perl for some arcane reason *insists*
        # on calling ld instead of teh correct gcc for linking.
        # and it's not being convinced by setting config ld=>gcc
        # in any of the ways listed in https://metacpan.org/pod/Module::Build::Cookbook
        # but calling gcc <same-args-as-the-ld-call> does fix it.
        # so we... symlink ld = gcc
        buildPhase = ''
          runHook preBuild
          perl Build.PL --prefix=$out
          mkdir path_intercept
          cd path_intercept
          ln -s `${pkgs.which}/bin/which gcc` ld
          cd ..
          export PATH=./path_intercept:$PATH
          ./Build build
          runHook postBuild
        '';
      };

      DataStag = pkgs.perl534Packages.buildPerlPackage {
        pname = "Data-Stag";
        version = "0.14";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/C/CM/CMUNGALL/Data-Stag-0.14.tar.gz";
          sha256 = "4ab122508d2fb86d171a15f4006e5cf896d5facfa65219c0b243a89906258e59";
        };
        propagatedBuildInputs = [pkgs.perl534Packages.IOString];
        meta = {description = "Structured Tags";};
      };

      libxmlperl = pkgs.perl534Packages.buildPerlPackage {
        pname = "libxml-perl";
        version = "0.08";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/K/KM/KMACLEOD/libxml-perl-0.08.tar.gz";
          sha256 = "4571059b7b5d48b7ce52b01389e95d798bf5cf2020523c153ff27b498153c9cb";
        };
        buildInputs = [pkgs.perl534Packages.XMLParser];
        meta = {};
      };

      BioPerl = pkgs.perl534Packages.buildPerlPackage rec {
        pname = "BioPerl";
        version = "1.7.8"; # slightly newer than requested
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/C/CJ/CJFIELDS/BioPerl-${version}.tar.gz";
          sha256 = "c490a3be7715ea6e4305efd9710e5edab82dabc55fd786b6505b550a30d71738";
        };
        buildInputs = with pkgs.perl534Packages; [
          TestMemoryCycle
          TestWeaken
          TestDeep
          TestWarn
          TestDifferences
          TestException
        ];
        propagatedBuildInputs = with pkgs.perl534Packages; [
          DBFile
          DataStag
          Error
          Graph
          HTTPMessage
          IOString
          IOStringy
          IPCRun
          LWP
          ListMoreUtils
          SetScalar
          TestMost
          TestRequiresInternet
          URI
          XMLDOM
          XMLLibXML
          XMLSAX
          XMLSAXBase
          XMLSAXWriter
          XMLTwig
          XMLWriter
          YAML
          libxmlperl
        ];
        meta = {
          homepage = "https://metacpan.org/release/BioPerl";
          description = "Perl modules for biology";
          license = with pkgs.lib.licenses; [artistic1 gpl1Plus];
        };
      };

      SetIntervalTree = pkgs.perl534Packages.buildPerlPackage {
        pname = "Set-IntervalTree";
        version = "0.12";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/S/SL/SLOYD/Set-IntervalTree-0.12.tar.gz";
          sha256 = "6fd4000e4022968e2ce5b83c07b189219ef1925ecb72977b52a6f7d76adbc349";
        };
        buildInputs = [pkgs.perl534Packages.ExtUtilsCppGuess];
        meta = {
          description = "Perform range-based lookups on sets of ranges";
          license = with pkgs.lib.licenses; [artistic1 gpl1Plus];
        };
      };

      BioDBHTS = pkgs.perl534Packages.buildPerlModule {
        pname = "Bio-DB-HTS";
        version = "3.01";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/A/AV/AVULLO/Bio-DB-HTS-3.01.tar.gz";
          sha256 = "12a6bc1f579513cac8b9167cce4e363655cc8eba26b7d9fe1170dfe95e044f42";
        };
        buildInputs = [pkgs.htslib pkgs.pkg-config pkgs.zlib pkgs.bzip2.dev pkgs.lzma];
        propagatedBuildInputs = [BioPerl];
        meta = {
          description = "Perl interface to HTS library for DNA sequencing";
          license = pkgs.lib.licenses.asl20;
        };
        # use gcc instead of ld for linking and all is well
        buildPhase = ''
          runHook preBuild
          perl Build.PL --prefix=$out
          mkdir path_intercept
          cd path_intercept
          ln -s `${pkgs.which}/bin/which gcc` ld
          cd ..
          export PATH=./path_intercept:$PATH
          ./Build build
          runHook postBuild
        '';
      };
    in
      pkgs.perl534Packages.buildPerlModule rec {
        pname = "ensembl-vep";
        version = "1.3.1";
        src = pkgs.fetchFromGitHub {
          owner = "Ensembl";
          repo = "ensembl-vep";
          rev = "316682594c11101535882b29983e07cd2cb53420";
          sha256 = "sha256-lyRt3cqsHdCFBeAdj9wgXorxi/7h1jgVX1cDWyePoBk=";
        };
        src_ensembl = pkgs.fetchurl {
          url = "https://github.com/Ensembl/ensembl/archive/release/106.zip";
          sha256 = "sha256-TlrJSEBwXJV8EIu5t9hG/HAPxn1RUnwQvylHzzfQZpI=";
        };
        src_ensembl_sub = pkgs.fetchurl {
          url = "https://api.github.com/repos/Ensembl/ensembl/commits?sha=release/106";
          sha256 = "sha256-p2DfWIYcmZzz/bp29rL20fN9TefIdds94mLVxUevKt4=";
        };
        src_ensembl_variation = pkgs.fetchurl {
          url = "https://github.com/Ensembl/ensembl-variation/archive/release/106.zip";
          sha256 = "sha256-ieaZESEab7myPSdA1/4Q8ce5RW9NuVhJT/LWiOM042s=";
        };
        src_ensembl_variation_sub = pkgs.fetchurl {
          url = "https://api.github.com/repos/Ensembl/ensembl-variation/commits?sha=release/106";
          sha256 = "sha256-LD1uEr7jEjH8+0zARsnmyspuGh2g6z3uEFqqi3NoANk=";
        };
        src_ensembl_funcgen = pkgs.fetchurl {
          url = "https://github.com/Ensembl/ensembl-funcgen/archive/release/106.zip";
          sha256 = "sha256-GWAQZ/WBUvkhejo9wnVjmxtWRm2A2zGiaJL0yPihMk8=";
         };
         src_ensembl_funcgen_sub = pkgs.fetchurl {
           url = "https://api.github.com/repos/Ensembl/ensembl-funcgen/commits?sha=release/106";
           sha256 = "sha256-7MaVWjuLks2T1mQ9o2xDV+DM+3eOSMb++aVi2bza86M=";
         };
         src_ensembl_io = pkgs.fetchurl {
           url ="https://github.com/Ensembl/ensembl-io/archive/release/106.zip";
           sha256 = "sha256-UEU7ugv+5Mg43Wf1hXUwBzAGkCRRsLK45pa1QGIYAwE=";
         };
         src_ensembl_io_sub = pkgs.fetchurl {
           url = "https://api.github.com/repos/Ensembl/ensembl-io/commits?sha=release/106";
           sha256 = "sha256-hA2y0WdWYlw7uSB4OxK9A5iBzY7KAR3UqA8olrB3YAE=";
         };
         # src_indexd = pkgs.fetchurl {
         #   url = "http://ftp.ensembl.org/pub/release-106/variation/indexed_vep_cache/homo_sapiens_vep_106_GRCh38.tar.gz";
         # };

        nativeBuildInputs = with pkgs; [
          perl
          perl534Packages.ArchiveZip
          perl534Packages.DBI
          perl534Packages.DBDmysql
          perl534Packages.JSON
          perl534Packages.PerlIOgzip
          SetIntervalTree
          BioBigFile
          curl
          which
          unzip
          git
          htslib
          samtools
          #bzip2.dev
          #zlib
          #lzma

          perl534Packages.LWP
          BioDBHTS
        ];
        patches = [./install.patch];
        buildPhase = ''
          mkdir -p ./Bio/tmp
          mkdir -p $out/cache/tmp
          cp ${src_ensembl} ./Bio/tmp/ensembl.zip
          cp ${src_ensembl_sub} /build/source/pid.ensembl.sub
          cp ${src_ensembl_variation} ./Bio/tmp/ensembl-variation.zip
          cp ${src_ensembl_variation_sub} pid.ensembl-variation.sub
          cp ${src_ensembl_funcgen} ./Bio/tmp/ensembl-funcgen.zip
          cp ${src_ensembl_funcgen_sub} pid.ensembl-funcgen.sub
          cp ${src_ensembl_io} ./Bio/tmp/ensembl-io.zip
          cp ${src_ensembl_io_sub} pid.ensembl-io.sub
          perl INSTALL.pl --NO_UPDATE  --NO_BIOPERL --NO_HTSLIB --AUTO a -s Homo_sapiens --CACHEDIR $out/cache --ASSEMBLY GRCh38 
        '';
        installPhase = ''
          cp * $out -r
        '';
        checkPhase = ":";
        outputs = ["out"];
        #
        #  cp ${src_indexd} $out/cache/tmp/homo_sapiens_vep_106_GRCh38.tar.gz
      });
  };
}
