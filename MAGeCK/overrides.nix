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
      mageck = prev.mageck.overridePythonAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.python3Packages.setuptools];
      });
    }
  )
]
