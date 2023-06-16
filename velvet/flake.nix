{
  description = "Bowtie aligner";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      # "x86_64-darwin"
      # "aarch64-linux"
      # "aarch64-darwin"
    ]; # i
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    # package.
    defaultPackage = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        velvet= pkgs.stdenv.mkDerivation rec {
          pname = "velvet";
          version = "1.2.10";
          src = pkgs.fetchFromGitHub {
            owner = "dzerbino";
            repo = "velvet";
            rev = "9adf09f7ded7fedaf6b0e5e4edf9f46602e263d3";
            sha256 = "sha256-FFxiOc8LuJMZaQiX+dczZ2genBdN1MuFo7qHyAqktSk=";
          };
          nativeBuildInputs = [pkgs.zlib];
          installPhase = ''
            mkdir $out/bin -p
            cd /build
            cp source/velveth* $out/bin/
            '';
        };
      in
        velvet
    );
  };
}
