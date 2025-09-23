{
  description = "Rabbit Trim FastQ parser";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.05"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    # Generate a user-friendly version number.
    #version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
      # "x86_64-darwin"
      # "aarch64-linux"
      # "aarch64-darwin"
    ]; #
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    version_hashes = {
        #"8d3d49e65a732143db0bd2a81d787529a2ea3325" = "sha256-uV0YL2uZx3jLfXdn3qZQUOPTXvgR7wiJYnXcd8N85bY=";
        "13eff891248353a94f42859e30caa99fe441603d" = "sha256-4rV6xAZTcTPOT8QgQyy+iotBEE1jQ/BRAUOh3Z/uuX4=";
    };
  in rec {
    rabbittrim = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          pname = "rabbittrim";
          version = version;
          src = pkgs.fetchFromGitHub {
            owner = "RabbitBio";
            repo = "RabbitTrim";
            rev = version;
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          NIX_CXXFLAGS_COMPILE = "-include cstdint";
          # (optional, if you want the C bits covered too)
          NIX_CFLAGS_COMPILE = "-include stdint.h";
          nativeBuildInputs = [pkgs.cmake pkgs.zlib.dev];
          buildInputs = [pkgs.zlib pkgs.gcc];
          installPhase = ''
              mkdir $out
              cp RabbitTrim $out/
            '';
        }
    );
    defaultPackage = forAllSystems (system: (rabbittrim.${system} "13eff891248353a94f42859e30caa99fe441603d"));
  };
}
