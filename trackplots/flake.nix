{
  description = "A basic flake using uv2nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    uv2nix.url = "github:/adisbladis/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix.url = "github:/nix-community/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    uv2nix,
    pyproject-build-systems,
    ...
  }: let
    pyproject-nix = uv2nix.inputs.pyproject-nix;
    workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    lib = pkgs.lib // {match = builtins.match;};

    defaultPackage = let
      # Generate overlay
      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
      #pyprojectOverrides = uv2nix_hammer_overrides.overrides pkgs;
      pyprojectOverrides = final: prev: {
          adjusttext = prev.adjusttext.overrideAttrs ( old: { nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem {setuptools = [];}; });
          asciitree = prev.asciitree.overrideAttrs ( old: { nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem {setuptools = [];}; });
          intervaltree = prev.intervaltree.overrideAttrs ( old: { nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem {setuptools = [];}; });
        # numba = prev.numba.overrideAttrs (
        #   old: {buildInputs = old.buildInputs or [] ++ [pkgs.tbb_2021_11.out];}
        # );
        # intervaltree = prev.intervaltree.overrideAttrs (
        #   old: {
        #     buildInputs =
        #       old.buildInputs
        #       or []
        #       ++ (
        #         final.resolveBuildSystem {setuptools = [];}
        #       );
        #   }
        # );
      };
      interpreter = pkgs.python311;
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
      pythonSet = pythonSet'.pythonPkgsHostHost.overrideScope (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          overlay
          pyprojectOverrides
        ]
      );
      virtualEnv = pythonSet.mkVirtualEnv "trackplot-venv" spec;
    in
      pkgs.stdenv.mkDerivation {
        name = "trackplot";
        buildInputs = [
          virtualEnv
        ];
        nativeBuildInputs = [pkgs.makeWrapper]; # provides a hook / shell function
        unpackPhase = ":";
        buildPhase = ''
          mkdir $out/bin -p
          makeWrapper  ${virtualEnv}/bin/trackplot $out/bin/trackplot
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
