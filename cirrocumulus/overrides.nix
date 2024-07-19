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

      pymongo = prev.pymongo.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-requirements-txt];
      });

      numcodecs = prev.numcodecs.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [final.py-cpuinfo];
      });
    }
  )
]
