{
  description = "KTrim an extra-fast and accurate adapter- and quality-trimmer for sequencing data";

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
      #"8d3d49e65a732143db0bd2a81d787529a2ea3325" = "sha256-uV0YL2uZx3jLfXdn3qZQUOPTXvgR7wiJYnXcd8N85bY="; # that won't build because of some undeclared variable
      "43e03952517d445ae5170392fcd0ec0b4f5b5be9" = "sha256-HmCD+tAjlK7PMVLM792De1UIvSSMFrAluPGQTuI/cS4=";
    };
  in rec {
    ktrim = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.stdenv.mkDerivation {
          pname = "ktrim";
          version = version;
          src = pkgs.fetchFromGitHub {
            owner = "hellosunking";
            repo = "KTrim";
            rev = version;
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          nativeBuildInputs = [];
          buildInputs = [pkgs.zlib.dev];
          buildPhase = ''
              ls bin
              rm bin/ktrim
              make
            '';
          installPhase = ''
              mkdir $out
              cp bin/ktrim $out
            '';
        }
    );
    defaultPackage = forAllSystems (system: (ktrim.${system} "43e03952517d445ae5170392fcd0ec0b4f5b5be9"));
  };
}
