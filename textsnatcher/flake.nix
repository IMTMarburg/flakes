{
  description = "Subread aligner";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # doesn't matter much

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;

      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ]; # it's java afterall
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {

      # package.
      defaultPackage = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.stdenv.mkDerivation rec {
          pname = "textsnatcher";
          version = "2.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "RajSolai";
            repo = "TextSnatcher";
            rev = "7192ac12cf875e2ee5337792436456a1d8a86243";
          };
          nativeBuildInputs = with pkgs; [granite gtk gobjectw gdk-pixbuf libhand libportal scrot tesseract5 meson];
        });
    };
}
