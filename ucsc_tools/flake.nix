{
  description = "flake for sratoolkit";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
  # this line assume that you also have nixpkgs as an input

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
      ]; # "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ]; guess we could adjust the url...
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {

      # package.
      defaultPackage = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          version = "v423";
          src = fetchTarball {
            url =
              "https://hgdownload.soe.ucsc.edu/admin/exe/userApps.archive/userApps.${version}.src.tgz";
            sha256 =
              "sha256:1qi7pnz2lhq9gr3a1ljvg560k5zs3k72y2a5zzn9k1cv80ffik0y";
          };

        in pkgs.stdenv.mkDerivation {
          pname = "ucsc_liftover";
          src = src;
          version = version;
          #autoPatchelfIgnoreMissingDeps=true; # libidn.11 - but nixpkgs has .12
          sourceRoot = "./source";
          prePatch = ''
            patchShebangs kent/src/checkUmask.sh
          '';
          installPhase = ''
            mkdir $out/bin -p
            cp bin/* $out/bin
          '';
          nativeBuildInputs = with pkgs; [
            libmysqlclient
            libpng
            openssl
            bash
            rsync
            libuuid
          ];
        });
    };
}
