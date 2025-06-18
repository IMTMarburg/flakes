{
  description = "STAR aligner";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    version_hashes = {
      "v1.22.3" = "sha256-EMVz/sI1rRZX4ReFd3ixO4eRhB1NbmsTEvT6SqGQyTI=";
    };
  in rec {
    seqfu2 = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
      src = "https://github.com/telatin/seqfu2/releases/download/${version}/SeqFu-${version}-Linux-x86_64.zip";
    in
      # wrap binary packages
      # I'd have prefered to build, but nim is troublesome / a path not often traveled in nixspace.
      pkgs.stdenv.mkDerivation {
        pname = "seqfu2";
        inherit version;
        src = pkgs.fetchurl {
          url = src;
          sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
        };
        nativeBuildInputs = [pkgs.unzip pkgs.autoPatchelfHook pkgs.makeWrapper];
        buildInputs = [pkgs.zlib pkgs.libgcc pkgs.stdenv.cc.cc.lib pkgs.pcre];
        installPhase = ''
          mkdir -p $out/bin
          unzip -o $src -d $out
          chmod +x $out/bin/*
          for f in "$out/bin/"*; do
            wrapProgram $f \
              --set LD_LIBRARY_PATH ${pkgs.pcre.out}/lib
          done
        '';
      });

    # pkgs.buildNimPackage {
    #   pname = "seqfu";
    #   version = version;
    #   src = pkgs.fetchFromGitHub {
    #     owner = "telatin";
    #     repo = "seqfu2";
    #     rev = version;
    #     sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
    #   };
    #   #nativeBuildInputs = [pkgs.zlib];
    #   nimbleFile = "seqfu.nimble";
    #   lockFile = ./lock.json;
    #   patches = [./001_named_bin_bin.patch];
    #   # postBuild = ''
    #   #   ls ./
    #   #   cat config.nims
    #   #   env
    #   #   aeu
    #   # '';
    # });
    defaultPackage = forAllSystems (system: (seqfu2.${system} "v1.22.3"));
  };
}
