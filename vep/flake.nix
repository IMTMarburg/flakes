{
  description = "Ensembl VEP (Variant Effect Predictor)";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg:
            builtins.elem (pkg.pname) ["kent"];
        };
      });
  in {
    defaultPackage = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};

      # ---------------------------------------------------------------
      # CPAN / non-nixpkgs Perl dependencies that VEP's docs list as
      # required or recommended: Archive::Zip, DBI (in nixpkgs already),
      # DBD::mysql, Set::IntervalTree, JSON, PerlIO::gzip,
      # Bio::DB::BigFile (needs UCSC "kent" source), Bio::DB::HTS
      # (needs BioPerl). These are unchanged from before -- they build
      # fine, the only thing that was actually broken was how the
      # Ensembl core API got wired into PERL5LIB.
      # ---------------------------------------------------------------

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
            cp /build/source/src/* $out/src -r
            mkdir $out/src/lib/ -p
            ln -s -t $out/src/lib $out/lib/jkweb.a
          '';
      });

      BioBigFile = pkgs.perl534Packages.buildPerlModule {
        pname = "Bio-BigFile";
        version = "1.07";
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
        propagatedBuildInputs = [BioPerl pkgs.perl534Packages.IOString];
        postPatch = ''
          substituteInPlace Build.PL \
          --replace "'-pthread'" "'-lpthread'," \
          --replace "'-Wformat=0'," "'-Wformat=0', '-Wno-format-security', '-pthread', "

          export MACHTYPE=$(uname -m)
        '';
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
        version = "1.7.8";
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

      # ---------------------------------------------------------------
      # Ensembl core API. This is what INSTALL.pl normally fetches and
      # installs at runtime -- we vendor it ourselves as plain
      # fetchurl'd zips (fixed-output derivations get network access
      # even inside the nix sandbox) and just unzip them. We never run
      # INSTALL.pl at all, so no install.patch is needed anymore.
      # ---------------------------------------------------------------
      ensemblRelease = "106";

      mkEnsemblApiModule = name: src:
        pkgs.stdenv.mkDerivation {
          pname = name;
          version = ensemblRelease;
          inherit src;
          nativeBuildInputs = [pkgs.unzip];
          # GitHub's zip archives extract to a single top-level dir
          # named e.g. "ensembl-release-106" -- we don't want to
          # hardcode that, so just glob for it.
          unpackPhase = ''
            unzip -q $src -d unpacked
          '';
          installPhase = ''
            mkdir -p $out
            cp -r unpacked/*/modules $out/modules
          '';
        };

      ensemblCore = mkEnsemblApiModule "ensembl" (pkgs.fetchurl {
        name = "ensembl_src";
        url = "https://github.com/Ensembl/ensembl/archive/release/${ensemblRelease}.zip";
        sha256 = "sha256-TlrJSEBwXJV8EIu5t9hG/HAPxn1RUnwQvylHzzfQZpI=";
      });

      ensemblVariation = mkEnsemblApiModule "ensembl-variation" (pkgs.fetchurl {
        name = "ensembl_variation_src";
        url = "https://github.com/Ensembl/ensembl-variation/archive/release/${ensemblRelease}.zip";
        sha256 = "sha256-ieaZESEab7myPSdA1/4Q8ce5RW9NuVhJT/LWiOM042s=";
      });

      ensemblFuncgen = mkEnsemblApiModule "ensembl-funcgen" (pkgs.fetchurl {
        name = "ensembl_funcgen_src";
        url = "https://github.com/Ensembl/ensembl-funcgen/archive/release/${ensemblRelease}.zip";
        sha256 = "sha256-GWAQZ/WBUvkhejo9wnVjmxtWRm2A2zGiaJL0yPihMk8=";
      });

      ensemblIO = mkEnsemblApiModule "ensembl-io" (pkgs.fetchurl {
        name = "ensembl_io_src";
        url = "https://github.com/Ensembl/ensembl-io/archive/release/${ensemblRelease}.zip";
        sha256 = "sha256-UEU7ugv+5Mg43Wf1hXUwBzAGkCRRsLK45pa1QGIYAwE=";
      });

      # All the runtime Perl deps that need to end up in PERL5LIB
      # alongside VEP's own "modules" dir and the ensembl core API.
      #
      # IMPORTANT: unlike buildPerlPackage's automatic wrapping,
      # perl534Packages.makePerlPath does NOT walk propagatedBuildInputs
      # recursively -- it only includes exactly what's listed here. So
      # BioPerl (needed directly by the ensembl core API, not just by
      # BioDBHTS/BioBigFile that propagate it) and everything BioPerl
      # itself propagates must be listed explicitly too.
      perlRuntimeDeps = with pkgs.perl534Packages;
        [
          ArchiveZip
          DBI
          DBDmysql
          JSON
          PerlIOgzip
          SetIntervalTree
          BioBigFile
          BioDBHTS
          LWP
          BioPerl
          TryTiny
        ]
        ++ BioPerl.propagatedBuildInputs;
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "ensembl-vep";
        version = "1.3.1";
        src = pkgs.fetchFromGitHub {
          owner = "Ensembl";
          repo = "ensembl-vep";
          rev = "316682594c11101535882b29983e07cd2cb53420";
          sha256 = "sha256-lyRt3cqsHdCFBeAdj9wgXorxi/7h1jgVX1cDWyePoBk=";
        };

        # perl534Packages.perl in nativeBuildInputs is what makes
        # patchShebangs below rewrite "#!/usr/bin/env perl" to point at
        # this exact interpreter, instead of leaving it to resolve
        # against $PATH at runtime (which previously picked up an
        # unrelated Perl 5.40 and broke loading the CPAN deps below,
        # which are all compiled against 5.34.1).
        nativeBuildInputs = [pkgs.makeWrapper pkgs.perl534Packages.perl];
        buildInputs = [
          pkgs.htslib
        ];
        # VEP itself is pure Perl -- there is nothing to compile or
        # configure. We deliberately do NOT run INSTALL.pl.
        dontBuild = true;
        dontConfigure = true;

        installPhase = ''
          mkdir -p $out/bin
          cp -r . $out

          mv $out/vep $out/bin/vep
          mv $out/filter_vep $out/bin/filter_vep
          mv $out/haplo $out/bin/haplo
          mv $out/variant_recoder $out/bin/variant_recoder

          patchShebangs $out/bin

          perl5lib="$out/modules:${ensemblCore}/modules:${ensemblVariation}/modules:${ensemblFuncgen}/modules:${ensemblIO}/modules:${pkgs.perl534Packages.makePerlPath perlRuntimeDeps}"

          for prog in vep filter_vep haplo variant_recoder; do
            wrapProgram $out/bin/$prog \
              --set PERL5LIB "$perl5lib" \
              --prefix PATH : "${pkgs.htslib}/bin"
          done
        '';

        meta = {
          description = "Ensembl Variant Effect Predictor";
          homepage = "https://www.ensembl.org/info/docs/tools/vep/index.html";
          license = pkgs.lib.licenses.asl20;
        };
      });
  };
}
