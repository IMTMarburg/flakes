{
  description = "Velvet assembler";

  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        # "x86_64-darwin"
        # "aarch64-linux"
        # "aarch64-darwin"
      ]; # i
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # package.
      defaultPackage = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          dnmtools = pkgs.stdenv.mkDerivation rec {
            pname = "dnmtools";
            version = "1.5.1";
            # src = pkgs.fetchFromGitHub {
            #   owner = "smithlabcode";
            #   repo = "dnmtools";
            #   rev = "9e95a43490f22894ffd7c08db83ac4bb942e5e69";
            #   sha256 = "sha256-L2WIjNVmBkBofyEfRZ4oW7KZmzJVuW3oKteXf8CxkGU=";
            # };
            # release has configure files...
            src = pkgs.fetchurl {
              url = "https://github.com/smithlabcode/dnmtools/releases/download/v1.5.1/dnmtools-1.5.1.tar.gz";
              sha256 = "sha256-aF8ZXbKyQNv1jOnz0CT8ZqDuqFz9Dqv4cOI2noclSBs=";
            };
            nativeBuildInputs = [
              pkgs.zlib
              pkgs.htslib
              pkgs.libdeflate
              pkgs.gsl
            ];
            buildPhase = ''
              ls -la
              ./configure --prefix=$out
              make
            '';
            # installPhase = ''
            #   mkdir $out/bin -p
            #   cd /build
            #   cp source/velvet* $out/bin/
            #   '';
          };
        in
        dnmtools
      );
    };
}
