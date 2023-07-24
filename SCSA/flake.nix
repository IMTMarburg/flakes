{
  description = "SCSA: cell type annotation for single-cell RNA-seq data";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.05"; # I'm pretty sure it will start failing once pands is newer than 1.5.x

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      # "x86_64-darwin"
      # "aarch64-linux"
      # "aarch64-darwin"
    ]; # i
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    # package.
    defaultPackage = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        mypython = pkgs.python3.withPackages (ps: with ps; [numpy scipy openpyxl pandas]);
      in
        pkgs.stdenv.mkDerivation rec {
          pname = "SCSA";
          version = "1.1";
          src = pkgs.fetchFromGitHub {
            owner = "bioinfo-ibms-pumc";
            repo = "SCSA";
            rev = "dfa5ff64c46b66eae3c1c797c449be22cfe15ea6";
            sha256 = "sha256-iwOxeQiKiCmdYNNCcB69rq6VxEqOZXjyzHpHATAHXy4=";
          };
          buildInputs = [mypython];
          buildPhase = ":";
          installPhase = ''
            mkdir $out/bin -p
            printf "#!${mypython}/bin/python3\n" > $out/bin/SCSA.py
            cat SCSA.py >> $out/bin/SCSA.py
            chmod +x $out/bin/SCSA.py
            substituteInPlace $out/bin/SCSA.py \
              --replace "whole.db" "$out/share/whole.db"
            mkdir $out/share/ -p
            cp *.db $out/share/
          '';
          meta = with pkgs.lib; {
            homepage = "https://github.com/bioinfo-ibms-pumc/SCSA";
            description = "SCSA: cell type annotation for single-cell RNA-seq data";
            longDescription = ''
              Currently most methods take manual strategies to annotate cell types after clustering the single-cell RNA-seq data. Such methods are labor-intensive and heavily rely on user expertise, which may lead to inconsistent results. We present SCSA, an automatic tool to annotate cell types from single-cell RNA-seq data, based on a score annotation model combining differentially expressed genes and confidence levels of cell markers in databases. Evaluation on real scRNA-seq datasets that SCSA is able to assign the cells into the correct types at a fully automated mode with a desirable precision.
            '';
            license = licenses.gpl3;
            #maintainers = with maintainers; [ AndersonTorres ];
            platforms = platforms.unix;
          };
        }
    );
  };
}
