{
  description = "flake for gdc-client";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";
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
          version = "1.6.1";
          src = pkgs.fetchzip {
            url =
              "https://gdc.cancer.gov/files/public/file/gdc-client_v1.6.1_Ubuntu_x64.zip";
            sha256 =
              "sha256-fimW3cnHWv7XnWfzcKqgYefkhYK66/TV36a5uq5K5wk=";
          };
          #autoPatchelfIgnoreMissingDeps=true; # libidn.11 - but nixpkgs has .12
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            zlib
                    ];
          buildPhase = "";
          installPhase = ''
            mkdir $out/bin -p
            cp gdc-client $out/bin
          '';
        });
    };
}
