{
  description = "flake for pystack";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    mach-nix,
    pypi-deps-db,
    flake-utils,
  }: let
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    defaultPackage = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.python3Packages.buildPythonApplication {
        name = "pystack";
        version = "1.0.1";
        src = pkgs.fetchFromGitHub {
          owner = "bloomberg";
          repo = "pystack";
          rev = "0b8d354de1a2e451e3d978dc266765c20a2e91e9";
          hash = "sha256-dIor0J8Z9YydKGDQk7ibCrGP0WeoapNN4wEB1gWGMsc=";
        };
        nativeBuildInputs = [
          pkgs.python3Packages.setuptools
          pkgs.python3Packages.wheel
          pkgs.python3Packages.cython
          pkgs.libelf
          pkgs.elfutils
        ];
        buildInputs = [
          pkgs.libelf
          pkgs.elfutils
        ];
        # set cython search path to include ${pkgs.elfutils}/include
        CPPFLAGS = "-I${pkgs.elfutils}/include -I${pkgs.libelf}/include";
        LDFLAGS = "-L${pkgs.elfutils}/lib -L${pkgs.libelf}/lib";
      });
  };
}
