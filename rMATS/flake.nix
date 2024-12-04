{
  description = "flake for WhichTF";
  # why don't we just add it to tto a float and compare to <3.6

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    rMats = pkgs: let
      src = pkgs.fetchFromGitHub {
        owner = "Xinglab";
        repo = "rmats-turbo";
        rev = "v4.3.0";
        sha256 = "sha256-LlfbTcVHh2fhNHQ2wbuNHHphOx50Jem/u2hqQuPQ2x4=";
      };
      version = "4.3.0";
      rMats_pipeline = pkgs.python310Packages.buildPythonPackage {
        pname = "rmats-pipeline";
        patches = [./bamtools.patch ./python_module.patch];
        inherit version src;
        preConfigure = ''
          cd rMATS_pipeline
        '';
        buildInputs = [pkgs.python310Packages.cython pkgs.bamtools pkgs.zlib];
      };
      my_python = pkgs.python310.withPackages (p: [rMats_pipeline]);
      rMats_C = pkgs.stdenv.mkDerivation {
        pname = "rmats_C";
        inherit version src;
        buildInputs = [pkgs.gsl pkgs.zlib pkgs.gfortran pkgs.gfortran.cc pkgs.blas pkgs.lapack];
        preBuild = ''
          cd rMATS_C
        '';
        installPhase = ''
          mkdir $out/bin -p
          INSTALL_PATH=$out/bin make install
        '';
      };
    in
      pkgs.stdenv.mkDerivation {
        pname = "rmats";
        inherit version src;
        patches = [./python_module.patch];
        buildPhase = ''
          mkdir $out/bin -p
          cp rmats.py $out/bin/
          chmod +x $out/bin/rmats.py
          substituteInPlace $out/bin/rmats.py --replace-fail "#!/usr/bin/env python" "#!${my_python}/bin/python"
          ln -s ${rMats_C}/bin/rMATSexe $out/bin/
          cp rMATS_R $out/bin -r
          cp rMATS_P $out/bin -r
          mkdir $out/bin/rMATS_C
          mv $out/bin/rMATSexe $out/bin/rMATS_C
        '';
        installPhase = ":";
      };
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in {
        default = rMats pkgs;
      }
    );
    devShell = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.mkShell {
          packages = [
            (rMats pkgs)
            #(pythonEnv pkgs)
          ];
        }
    );
  };
}
