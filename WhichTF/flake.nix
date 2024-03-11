{
  description = "flake for WhichTF";
  # why don't we just add it to tto a float and compare to <3.6

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils = {
      url = "github:numtide/flake-utils?rev=7e5bf3925f6fbdfaf50a2a7ca0be2879c4261d19";
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
        pname = "WhichTF";
        version = "0.2"; # must match your git hash
        src = pkgs.fetchFromBitbucket {
          owner = "bejerano";
          repo = "whichtf";
          rev = "44b8092e5ffc0187be7a08efdb9bd3062f13e4ea";
          sha256 = "sha256-spG6J//EvAlDPU4i5ajFDmKOSo19V/5cpM+7w1e4GoM=";
        };
        buildInputs = [pkgs.R];
        propagatedBuildInputs = with pkgs.python3.pkgs; [numpy pandas scipy nose pip];
        patches = [./patch_rpy2_dependency.patch];
        hg38 = pkgs.fetchurl {
          url = "http://bejerano.stanford.edu/whichtf/reference_data/current/hg38.tar.gz";
          sha256 ="sha256-xsVkmYq5MYh1TeTgZ+Xx9bo+O9+xMYbgZb1AqAvymco=";
        };
        postInstall = ''
          mkdir -p $out/data
          tar C $out/data -xzf $hg38
        '';

        # automatic requirements extraction fails, just like MACS is not in pypi-deps-db because of
        # stupid setup.py wizzardry
      });
  };
}
