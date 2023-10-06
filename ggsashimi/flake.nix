{
  description = "ggsashimi for splicing plots";
  # why don't we just add it to the python packages?
  # because we want it to be independent of our python packages / python version
  # (e.g. MACS2 2.2.7.1 is (trivially) not python 3.10 compatible,
  # because they cast the version to a float and compare to <3.6

  inputs = {nixpkgs.url = "nixpkgs/nixos-23.05";};

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      #"x86_64-darwin" "aarch64-linux" "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    defaultPackage = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        myR = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            ggplot2
            data_table
            gridExtra
            svglite
          ];
        };
        ggsashimi = pkgs.stdenv.mkDerivation {
          pname = "ggsashimi";
          version = "1.1.5";
          src = pkgs.fetchFromGitHub {
            owner = "guigolab";
            repo = "ggsashimi";
            rev = "59a290a18178acf13794a89e752c3434876fb812";
            sha256 = "sha256-/O3VfzgVVn/KOlhAXigPGZZOg5L6a949ieQ1n9Ducoo=";
          };
          buildPhase = '':'';
          installPhase = ''
            mkdir $out/bin -p
            cp ggsashimi.py $out/bin
            chmod +x $out/bin/ggsashimi.py
            substituteInPlace $out/bin/ggsashimi.py --replace "R --vanilla" "${myR}/bin/R --vanilla"
            substituteInPlace $out/bin/ggsashimi.py --replace "element_line(size" "element_line(linewidth"
            # fix shebang
          '';
          propagatedBuildInputs = [
            (pkgs.python3.withPackages (ps: with ps; [pysam]))
          ];
        };
      in
        ggsashimi
    );
  };
}
