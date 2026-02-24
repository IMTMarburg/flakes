{
  description = "flake for dropkick";
  # why don't we just add it to tto a float and compare to <3.6

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      overlays = [
        (final: prev: {
          python38 = prev.python38.override {
            packageOverrides = pyFinal: pyPrev: {
              pyarrow = pyPrev.pyarrow.overrideAttrs (old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ final.libxcrypt ];
              });
              flask-sqlalchemy = pyPrev.flask-sqlalchemy.overrideAttrs (old: {
                disabled = false;
              });
            };
          };
        })
      ];
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system overlays; });
      dropkick =
        pkgs:
        let
          ppp = pkgs.python38Packages;
          anndata = ppp.buildPythonPackage rec {
            pname = "anndata";
            version = "0.8.0";
            format = "flit";
            src = ppp.fetchPypi {
              inherit pname version;
              sha256 = "sha256-lNLMb3bAMXwKwoVk4wkrMTt60ZxzfWZwGWHz5iC5Bm4=";
            };
            nativeBuildInputs = [
              ppp.flit
              ppp.setuptools_scm
            ];
            propagatedBuildInputs = with ppp; [
              natsort
              pandas
              scipy
              h5py
              packaging
              importlib-metadata
            ];
            buildPhase = ''
              ${ppp.python.interpreter} -m flit build --format wheel
            '';
          };
          session-info = ppp.buildPythonPackage rec {
            pname = "session_info";
            version = "1.0.0";
            #format = "flit";
            src = ppp.fetchPypi {
              inherit pname version;
              sha256 = "sha256-PNpeA8ynA/Mq4urb1r2AtsIUQs+2DkEsIcuK1tXLtrc=";
            };
            nativeBuildInputs = [
            ];
            propagatedBuildInputs = with ppp; [
              stdlib-list
            ];
          };
          scanpy = ppp.buildPythonPackage rec {
            pname = "scanpy";
            version = "1.9.2";
            format = "flit";
            src = ppp.fetchPypi {
              inherit pname version;
              sha256 = "sha256-zwNCQsTehycRaClxlma7sY2NFBhZQiiUudbX9HQUAtc=";
            };
            nativeBuildInputs = [
              ppp.flit
              ppp.setuptools_scm
            ];
            propagatedBuildInputs = with ppp; [
              anndata
              h5py
              importlib-metadata
              joblib
              natsort
              networkx
              numba
              packaging
              pandas
              patsy
              scipy
              seaborn
              session-info
              statsmodels
              tqdm
              umap-learn
            ];
            buildPhase = ''
              ${ppp.python.interpreter} -m flit build --format wheel
            '';
          };
          # scanpy = ppp.buildPythonPackage {
          #   pname = "scanpy";
          #   version = "1.9.2";
          #   format = "pyproject";
          #   src = pkgs.fetchPypi {
          #     inherit pname version;
          #   };
          #   propagatedBuildInputs = with ppp; [
          #     numpy
          #     matplotlib
          #     scipy
          #     seaborn
          #     h5py
          #     tqdm
          #     scikit-learn
          #     statsmodels
          #     patsy
          #     networkx
          #     natsort
          #     joblib
          #     packaging
          #     #ppp.session-info
          #   ];
          # };

          pname = "dropkick";
          version = "1.2.8";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-S/vSOYSsEWaWkYGPKeHwAz4y3XwiNrFtii8g/mDJI8Y=";
          };
          dropkick_pkg = ppp.buildPythonPackage {
            inherit pname;
            inherit version;
            inherit src;
            preBuild = ''
              export NUMBA_CACHE_DIR=$(mktemp -d)
            '';

            nativeBuildInputs = [
              # fortran!
              pkgs.gfortran
            ];
            propagatedBuildInputs = with ppp; [
              numpy
              scipy
              pandas
              scikit-learn
              scikit-image
              matplotlib
              scanpy
              anndata
            ];
          };
        in
        dropkick_pkg;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = dropkick pkgs;
        }
      );
      # devShell = forAllSystems (
      #   system:
      #   let
      #     pkgs = nixpkgsFor.${system};
      #   in
      #   pkgs.mkShell {
      #     packages = [
      #       (dropkick pkgs)
      #       #(pythonEnv pkgs)
      #     ];
      #   }
      # );
    };
}
