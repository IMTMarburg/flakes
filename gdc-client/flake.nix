{
  description = "flake for gdc-client";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-24.11";
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
          pname = "gdc-client";
          version = "2.3.0";
          src = pkgs.fetchzip {
            url =
              "https://gdc.cancer.gov/system/files/public/file/gdc-client_2.3_Ubuntu_x64-py3.8-ubuntu-20.04.zip";
            sha256 =
              "sha256-tb6i7T5i/xMLIIsUQK8NvLPCC+gg9/OeBU7KSaWb068=";
          };
          #autoPatchelfIgnoreMissingDeps=true; # libidn.11 - but nixpkgs has .12
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            zlib
                    ];
          buildPhase = "${pkgs.unzip}/bin/unzip gdc-client_2.3_Ubuntu_x64.zip";
          installPhase = ''
            mkdir $out/bin -p
            ls -la
            cp gdc-client $out/bin
          '';
        });
    };
}
