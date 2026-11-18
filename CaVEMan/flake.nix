{
  description = "CaVEMan - SNV expectation maximisation based mutation calling algorithm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    caveman-src = {
      url = "github:cancerit/CaVEMan/1.15.5";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      caveman-src,
    }:
    let
      # linasm is hand-written x86_64 assembly (fasm), so this is the only
      # platform it (and therefore CaVEMan) builds on.
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          linasm = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "linasm";
            version = "1.13-unstable-2018-09-02";

            # The fork + commit CaVEMan's own setup.sh builds against: the 1.13
            # release plus upstream hotfixes (List, Deque, Vector, Array_SumAbs).
            src = pkgs.fetchFromGitHub {
              owner = "rurban";
              repo = "linasm";
              rev = "e33b4a083f8bbdcbd58018c9abc65047d20fd431";
              hash = "sha256-xnYqJu4SlMnscJ5Y7DQTMflnsiGWGA1Topm4VvKYyrY=";
            };

            nativeBuildInputs = [ pkgs.fasm ];

            # Use nixpkgs' fasm instead of the prebuilt binary in build/.
            makeFlags = [
              "AS=fasm"
              "prefix=${placeholder "out"}"
            ];

            enableParallelBuilding = true;

            meta = {
              description = "Fast assembly library for x86_64 Linux";
              homepage = "https://github.com/rurban/linasm";
              license = pkgs.lib.licenses.lgpl3Plus;
              platforms = [ "x86_64-linux" ];
            };
          });

          caveman = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "caveman";
            version = "1.15.5";

            src = caveman-src;

            buildInputs = [
              pkgs.htslib
              pkgs.zlib
              pkgs.xz
              pkgs.bzip2
              pkgs.curl
              linasm
              pkgs.perl
            ];

            postPatch = ''
              patchShebangs scripts tests/runtests.sh
              # Missing return type => implicit int, which GCC >= 14 rejects
              # (and which would truncate the returned char* on 64-bit).
              sed -i 's/^test_fai_access_get_count_length_all_contigs()/char *&/' tests/fai_access_tests.c
            '';

            # The upstream Makefile's DEBUG switch is inverted: DEBUG set => -O3,
            # unset => -g -O0. We want the optimised build.
            makeFlags = [
              "DEBUG=1"
              "CAVEMAN_VERSION=${finalAttrs.version}"
              "OPTINC=-I${linasm}/include"
              # Link against nixpkgs' shared htslib instead of the static
              # libhts.a symlink dance upstream does.
              "LFLAGS=-L${linasm}/lib"
              "prefix=${placeholder "out"}"
            ];

            buildFlags = [
              "make_bin"
              "./bin/caveman"
              "./bin/generateCavemanUMNormVCF"
              "copyscript"
            ];

            # GCC >= 14 makes this an error; upstream mixes `unsigned long long`
            # and `uint64_t` pointers, which are identical on x86_64.
            env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";

            enableParallelBuilding = true;

            doCheck = true;
            checkPhase = ''
              runHook preCheck
              make $makeFlags TEST_REF="$PWD/testData/genome.fa" test
              runHook postCheck
            '';

            installPhase = ''
              runHook preInstall
              install -Dm755 -t $out/bin bin/*
              runHook postInstall
            '';

            meta = {
              description = "SNV expectation maximisation based mutation calling algorithm";
              homepage = "https://github.com/cancerit/CaVEMan";
              license = pkgs.lib.licenses.agpl3Plus;
              mainProgram = "caveman";
              platforms = [ "x86_64-linux" ];
            };
          });
        in
        {
          inherit linasm caveman;
          default = caveman;
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.caveman ];
        };
      });
    };
}
