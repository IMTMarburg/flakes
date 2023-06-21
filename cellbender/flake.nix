{
  description = "Velvet assembler";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # I'm pretty sure it will start failing once pands is newer than 1.5.x

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
        pp = pkgs.python37Packages;
        anndata = pp.buildPythonPackage rec {
          pname = "anndata";
          version = "0.8.0";
          format = "flit";
          src = pp.fetchPypi {
            inherit pname version;
            sha256 = "sha256-lNLMb3bAMXwKwoVk4wkrMTt60ZxzfWZwGWHz5iC5Bm4=";
          };
          nativeBuildInputs = [
            pp.flit
            pp.setuptools_scm
          ];
          propagatedBuildInputs = [
            pp.natsort
            pp.pandas
            pp.scipy
            pp.h5py
            pp.packaging
            pp.importlib-metadata
          ];
          buildPhase = ''
            ${pp.python.interpreter} -m flit build --format wheel
          '';
        };
      in
        pp.buildPythonApplication rec {
          pname = "cellbender";
          version = "0.2.2";
          src = pkgs.fetchFromGitHub {
            owner = "broadinstitute";
            repo = "CellBender";
            rev = "d92cfc5a55c8b1771348468035993c52df975170";
            sha256 = "sha256-/sERZdt+YUFayEprrHTpL0suzzpzwjCM8qs5Z/9NLUE=";
          };
          patches = [./no_doc.patch];
          propagatedBuildInputs = with pp; [
            anndata
            numpy
            scipy
            tables
            pandas
            pyro-ppl
            scikit-learn
            matplotlib
            #sphinx
            #sphinx-rtd-theme
            #sphinx-autodoc-typehints
            #sphinxcontrib-programoutput
            #sphinx-argparse
          ];
          doCheck = false;
        }
    );
  };
}
