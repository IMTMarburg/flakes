{
  description = "SUPPA Fast, accurate, and uncertainty-aware differential splicing analysis across multiple condition";
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
        suppa = prev.suppa.overrideAttrs (
          old: {buildInputs = old.buildInputs or [] ++ [(final.resolveBuildSystem {setuptools = [];})];}
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
      virtualEnv = pythonSet.mkVirtualEnv "suppa-venv" spec;
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "SUPPA";
        version = "2.4";
        src = pkgs.fetchurl {
          url = "https://github.com/comprna/SUPPA/archive/refs/tags/v2.4.tar.gz";
          sha256 = "sha256-pxswF90TzrS4uDffriAes7xV+xHfyyAUNPb/HkczCTw=";
        };
        buildInputs = [
          virtualEnv
        ];
        nativeBuildInputs = [pkgs.makeWrapper]; # provides a hook / shell function
        unpackPhase = ":";
        buildPhase = ''
          mkdir $out/bin -p
          cat <<EOF > $out/bin/suppa
          #!${pkgs.bash}/bin/bash
          PYTHONPATH=$PYTHONPATH:$out/suppa/lib ${virtualEnv}/bin/python $out/suppa/SUPPA-2.4/suppa.py $@
          EOF
          chmod +x $out/bin/suppa
          mkdir $out/suppa -p
          cd $out/suppa && tar xf $src
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
