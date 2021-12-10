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
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "sratoolkit";
          version = "2.11.3";
          src = fetchTarball {
            url =
              "https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${version}/sratoolkit.${version}-ubuntu64.tar.gz";
            sha256 =
              "sha256:03f4ah49mlkvy6l3ywh1y1d3w19dpnifavl5slhq9wq0pdknwmh1";
          };
          autoPatchelfIgnoreMissingDeps=true; # libidn.11 - but nixpkgs has .12
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            zlib
            fuse
            bzip2
            stdenv.cc.cc.lib
            libidn
          ];
          buildPhase = "";
          installPhase = ''
            mkdir $out/bin -p
            cp bin/* $out/bin -r
          '';
        });
    };
}
