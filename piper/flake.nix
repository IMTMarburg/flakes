{
  description = "piper tts";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.05"; # doesn't matter much

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
  in {
    # package.
    defaultPackage = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
      espeak = pkgs.stdenv.mkDerivation {
        # patched espeak for piper...
        name = "espeak-ng-piper";
        version = "0.1";
        src = pkgs.fetchFromGitHub {
          owner = "rhasspy";
          repo = "espeak-ng";
          rev = "61504f6b76bf9ebbb39b07d21cff2a02b87c99ff";
          sha256 = "sha256-RBHL11L5uazAFsPFwul2QIyJREXk9Uz8HTZx9JqmyIQ=";
        };
        nativeBuildInputs = with pkgs; [
          autoconf
          automake
          which
          libtool
          pkg-config
          ronn
        ];
        configurePhase = ''
            ./autogen.sh
            ./configure \
          --without-pcaudiolib \
          --without-klatt \
          --without-speechplayer \
          --without-mbrola \
          --without-sonic \
          --with-extdict-cmn \
            --prefix=$out
        '';
      };
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "piper";
        version = "1.0.0";
        src = pkgs.fetchurl {
          url = "https://github.com/rhasspy/piper/releases/download/v1.0.0/piper_amd64.tar.gz";
          sha256 = "sha256-YwmjZgwo5rBZd4MUIsHowU9j8YF14btObYAvHf0JZ3Y=";
        };
        nativeBuildInputs = with pkgs; [
          autoPatchelfHook
          glibc
          stdenv.cc.cc.lib
          espeak
        ];
        installPhase = let
          libPath = pkgs.lib.makeLibraryPath [
            pkgs.glibc.out
            pkgs.stdenv.cc.cc.lib
            espeak
          ];
        in ''

          mkdir -p $out/bin
          mkdir -p $out/lib
          cp *.so* $out/lib
          rm $out/lib/*espeak* # we build our own with custom prefix
          cp piper $out/bin

          addAutoPatchelfSearchPath ${libPath}
          #addAutoPatchelfSearchPath $out/lib
          echo "libPath: ${libPath}"
          echo "done install"
        '';
      });
  };
}
