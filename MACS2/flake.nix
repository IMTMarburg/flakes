{
  description = "flake for MACS2";
  # why don't we just add it to the python packages?
  # because we want it to be independent of our python packages / python version
  # (e.g. MACS2 2.2.7.1 is (trivially) not python 3.10 compatible,
  # because they cast the version to a float and compare to <3.6 

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils = {
      url =
        "github:numtide/flake-utils?rev=7e5bf3925f6fbdfaf50a2a7ca0be2879c4261d19";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mach-nix = {
      url =
        "github:DavHau/mach-nix?rev=31b21203a1350bff7c541e9dfdd4e07f76d874be";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    pypi-deps-db = {
      url =
        "github:DavHau/pypi-deps-db?rev=a40ae14161503e607ebf770093d36a8e70f691fb"; # might need to update this if you update macs
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.mach-nix.follows = "mach-nix";
    };
  };

  outputs = { self, nixpkgs, mach-nix, pypi-deps-db, flake-utils }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {
      defaultPackage = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          mach-nix_ = (import mach-nix) {
            inherit pkgs;
            pypiDataRev = pypi-deps-db.rev;
            pypiDataSha256 = pypi-deps-db.narHash;
            python = "python38";
          };

        in mach-nix_.buildPythonApplication {

          pname = "MACS2";
          version = "2.2.7.1"; # must match your git hash
          src = builtins.fetchTarball {
            url =
              "https://github.com/macs3-project/MACS/tarball/00f489c1555dd15e3713a03f9357a33cbcef24b1";
            sha256 = "08zsgh65xbpv1md2s3wqmrk9g2mz6izmn59ryw5lbac54120p291";
          };
          # automatic requirements extraction fails, just like MACS is not in pypi-deps-db because of
          # stupid setup.py wizzardry
          requirements = "
            numpy>=1.17
            cython>=0.29
            pytest>=4.6
            pytest-cov>=2.8
            codecov>=2.0
            setuptools>=41.2
          ";
        });
    };
}
