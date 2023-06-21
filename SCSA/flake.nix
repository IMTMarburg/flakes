{
  description = "Velvet assembler";

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
        mypython = (pkgs.python3.withPackages (ps: with ps; [numpy scipy openpyxl pandas]));
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
        }
    );
  };
}
