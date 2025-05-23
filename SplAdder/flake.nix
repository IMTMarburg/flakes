{
  description = "A basic flake using uv2nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    uv2nix.url = "github:/adisbladis/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix.url = "github:/nix-community/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
  };
  outputs = {
    nixpkgs,
    uv2nix,
    ...
  }: let
    pyproject-nix = uv2nix.inputs.pyproject-nix;
    workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    defaultPackage = let
      # Generate overlay
      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
      #pyprojectOverrides = uv2nix_hammer_overrides.overrides pkgs;
      pyprojectOverrides = final: prev: {
        numba = prev.numba.overrideAttrs (
          old: {buildInputs = old.buildInputs or [] ++ [pkgs.tbb_2021_11.out];}
        );
        intervaltree = prev.intervaltree.overrideAttrs (
          old: {
            buildInputs =
              old.buildInputs
              or []
              ++ (
                final.resolveBuildSystem {setuptools = [];}
              );
          }
        );
      };
      interpreter = pkgs.python312;
      spec = {
        uv2nix-hammer-app = [];
      };

      # Construct package set
      pythonSet' =
        (pkgs.callPackage pyproject-nix.build.packages {
          python = interpreter;
        })
        .overrideScope
        overlay;

      # Override host packages with build fixups
      pythonSet = pythonSet'.pythonPkgsHostHost.overrideScope pyprojectOverrides;
      virtualEnv = pythonSet.mkVirtualEnv "spladder-venv" spec;
    in
      pkgs.stdenv.mkDerivation {
        name = "spladder";
        buildInputs = [
          virtualEnv
        ];
        nativeBuildInputs = [pkgs.makeWrapper]; # provides a hook / shell function
        unpackPhase = ":";
        buildPhase = ''
          mkdir $out/bin -p
          makeWrapper  ${virtualEnv}/bin/spladder $out/bin/spladder 
        '';
      };
  in {
    packages.x86_64-linux.default = defaultPackage;
    devShell.x86_64-linux = pkgs.mkShell {
      packages = [
        defaultPackage
      ];
      shellHook = ''
        # Undo dependency propagation by nixpkgs.
        unset PYTHONPATH
      '';
    };
  };
}
