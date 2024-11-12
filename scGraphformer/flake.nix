{
  description = "scGraphformer for clustering scRNAseq data.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    uv2nix.url = "github:/adisbladis/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix.url = "github:/nix-community/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    uv2nix_hammer_overrides.url = "github:TyberiusPrime/uv2nix_hammer_overrides";
  };
  outputs = {
    nixpkgs,
    uv2nix,
    uv2nix_hammer_overrides,
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
      pyprojectOverrides = uv2nix_hammer_overrides.overrides pkgs;
      #pyprojectOverrides = final: prev: {} ;
      interpreter = pkgs.python310;
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
      virtualEnv = pythonSet.mkVirtualEnv "scGraphformer-venv" spec;
    in
      pkgs.stdenv.mkDerivation {
        name = "scGraphFormer";
        src = pkgs.fetchFromGitHub {
          owner = "xyfan22";
          repo = "scGraphformer";
          rev = "11a50ea9753241669112f5738074e294bb122333";
          sha256 = "sha256-R1qhUQ803Nsx43WzU2AdZ6VAs9UHH9ct0qABEbqf0hs=";
        };
        buildInputs = [
          virtualEnv
        ];
        nativeBuildInputs = [pkgs.makeWrapper]; # provides a hook / shell function
        unpackPhase = ":";
        buildPhase = ''
          mkdir $out -p
          cp * $out -r
          mkdir $out/bin -p
          echo "${virtualEnv}/bin/python $out/main.py" > $out/bin/scGraphformer
          chmod +x $out/bin/scGraphformer
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
