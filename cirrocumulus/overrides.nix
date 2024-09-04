{
  defaultPoetryOverrides,
  pkgs,
  lib,
}: [
  defaultPoetryOverrides

  (
    final: prev: let
      buildSystems = lib.importJSON ./build-systems.json;
    in {
      array-api-compat = prev.array-api-compat.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.setuptools];
      });

      fsspec = prev.fsspec.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-vcs];
      });
      anndata = prev.anndata.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-vcs];
      });
      cirrocumulus = prev.cirrocumulus.override {
        preferWheel = true;
      };
      # cirrocumulus = prev.cirrocumulus.overridePythonAttrs (oldAttrs: {
      #   buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-vcs];
      #   preBuild = ''
      #     find .
      #   '';
      # });
      legacy-api-wrap = prev.legacy-api-wrap.overridePythonAttrs (old: {
        buildInputs = old.buildInputs ++ [pkgs.python3Packages.hatchling];
      });
      session-info = prev.session-info.overridePythonAttrs (old: {
        buildInputs = old.buildInputs ++ [pkgs.python3Packages.setuptools];
      });

      pymongo = prev.pymongo.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-requirements-txt];
      });
      scanpy = prev.scanpy.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-vcs];
      });

      numcodecs = prev.numcodecs.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [final.py-cpuinfo];
      });
      contourpy = prev.contourpy.override {
        preferWheel = true;
      };
    }
  )
]
