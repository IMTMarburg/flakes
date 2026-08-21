{
  description = "hello world application using uv2nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.11";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };
      buildsystem_overrides =
        final: prev:
        let
          buildSystemOverrides = {
            beers-utils = {
              setuptools = [ ];
            };
            stopit = {
              setuptools = [ ];
            };
            pysam = {
              setuptools = [ ];
            };
            datrie = {
              setuptools = [ ];
              cython = [ ];
            };
            connection-pool = {
              setuptools = [ ];
            };

            beers2 = {
              setuptools = [ ];
              cython = [ ];
              numpy = [ ];
            };
            camparee = {
              setuptools = [ ];
            };
          };
        in
        builtins.mapAttrs (
          name: spec:
          prev.${name}.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem spec;
          })
        ) buildSystemOverrides;

      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python311;
          local_overrides = final: prev: {
            pysam = prev.pysam.overrideAttrs (old: {
              buildInputs = old.buildInputs or [ ] ++ [
                pkgs.zlib
                pkgs.htslib
                pkgs.bzip2
                pkgs.xz.dev 
              ];
            });
            # gcc 14 upgrades that warning to an error 
            datrie = prev.datrie.overrideAttrs (old: {
              env = (old.env or { }) // {
                NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=incompatible-pointer-types";
              };
            });
          };
        in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
              buildsystem_overrides
              local_overrides
            ]
          )
      );

    in
    {
      packages = forAllSystems (
        system:
        let
          pythonSet = pythonSets.${system}.overrideScope editableOverlay;
          virtualenv = pythonSet.mkVirtualEnv "hello-world-dev-env" workspace.deps.default;
        in

        {
          default = virtualenv;
        }
      );
    };
}
