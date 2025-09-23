{
  description = "A basic flake using uv2nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
    uv2nix.url = "github:/adisbladis/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";

    pyproject-nix.url = "github:/nix-community/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix_hammer_overrides.url = "github:TyberiusPrime/uv2nix_hammer_overrides";
  };
  outputs =
    {
      nixpkgs,
      uv2nix,
      pyproject-build-systems,
      uv2nix_hammer_overrides,
      ...
    }:
    let
      pyproject-nix = uv2nix.inputs.pyproject-nix;
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      defaultPackage =
        let
          # Generate overlay
          overlay = workspace.mkPyprojectOverlay {
            sourcePreference = "wheel";
          };
          #pyprojectOverrides = uv2nix_hammer_overrides.overrides pkgs;
          user_overrides = final: prev: {
            numba = prev.numba.overrideAttrs (old: {
              #buildInputs = old.buildInputs or [ ] ++ [ pkgs.tbb_2021_11.out ];
              nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [
                (prev.resolveBuildSystem { setuptools = [ ]; })
              ];
            });
          };
          interpreter = pkgs.python312;
          spec = {
            uv2nix-hammer-app = [ ];
          };
          pyprojectOverrides = pkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            overlay # this order is important!
            (uv2nix_hammer_overrides.overrides pkgs)
            user_overrides
          ];

          # Construct package set
          pythonSet' =
            (pkgs.callPackage pyproject-nix.build.packages {
              python = interpreter;
            }).overrideScope
              pyprojectOverrides;

          # Override host packages with build fixups
          pythonSet = pythonSet'.pythonPkgsHostHost.overrideScope pyprojectOverrides;
          virtualEnv = pythonSet.mkVirtualEnv "concord-venv" spec;
        in
        pkgs.stdenv.mkDerivation {
          name = "concord";
          buildInputs = [ virtualEnv ];
          unpackPhase = ":";
          installPhase = ''
            mkdir -p $out/bin
            ln -s ${virtualEnv}/bin/python $out/bin/condord_python
          '';
        };
    in
    {
      packages.x86_64-linux.default = defaultPackage;
      devShell.x86_64-linux = pkgs.mkShell {
        packages = [
          defaultPackage
        ];
        shellHook = ''
          # Undo dependency propagation by nixpkgs.
          # doesn't matter either way for xengsort though.
          unset PYTHONPATH
        '';
      };
    };
}
