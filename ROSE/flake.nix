{
  description = "ROSE : RANK ORDERING OF SUPER-ENHANCERS";
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
        # myR = pkgs.rWrapper.override {
        #   packages = with pkgs.rPackages; [
        #   ];
        # };
        rose = pkgs.stdenv.mkDerivation {
          pname = "rose";
          version = "1.3.1";
          src = pkgs.fetchFromGitHub {
            owner = "stjude";
            repo = "ROSE";
            rev = "0bdce269083fcb9b4a3943efdb6693198a48e109";
            sha256 = "sha256-2iWSCe6a3j1mwy++nfgvEFtP7US67iwVijtdnuBIzTU=";
          };
          buildPhase = '':'';
          installPhase = ''
            mkdir $out/bin -p
            mkdir $out/ROSE -p
            cp annotation $out/ROSE -r
            cp bin/* $out/bin
            chmod +x $out/bin/*
            cp lib/ROSE_utils.py $out/bin
            # fix shebang
            patchShebangs $out/bin/ROSE_main.py
            patchShebangs $out/bin/ROSE_geneMapper.py
            patchShebangs $out/bin/ROSE_bamToGFF.py
            patchShebangs $out/bin/ROSE_geneMapper.py
          '';
          buildInputs = [pkgs.python3 pkgs.R];
          patches = [./fix_paths.patch ./make_sane.patch];
          #propagatedBuildInputs = [
            #(pkgs.python3.withPackages (ps: with ps; []))
          #];
        };
      in
        rose
    );
  };
}
