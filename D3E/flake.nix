{
  description = "D3E: Discrete Distributional Differential Expression";

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
        mypython = pkgs.python3.withPackages (ps: with ps; [numpy scipy mpmath]);
      in
        pkgs.stdenv.mkDerivation rec {
          pname = "D3E";
          version = "2019_01";
          src = pkgs.fetchFromGitHub {
            inherit pname;
            owner = "hemberg-lab";
            repo = "D3E";
            rev = "c81f8580553fd74742da20c5f40a1263ddcb587e";
            sha256 = "sha256-ayJ+6a5QOCEsQY4EDn+kjSvDqYgAS7mz/JQsieWzN2g=";
          };
          buildInputs = [mypython];
          patches = [./py3.patch];
          buildPhase = ":";
          installPhase = ''
            mkdir $out/bin -p
            cp *.py $out/bin
            chmod +x $out/bin/*.py

            SHEBANG="#!${mypython}/bin/python3"
            cd $out/bin
            for file in *.py
            do
              if [[ $(head -n 1 "$file") != "$SHEBANG" ]]; then
                cp "$file" tmp_file
                echo "$SHEBANG" > "$file"
                cat tmp_file >> "$file"
                rm tmp_file
              fi
            done

          '';
          meta = with pkgs.lib; {
            homepage = "https://github.com/hemberg-lab/D3E";
            description = "D3E: Discrete Distributional Differential Expression";
            longDescription = ''
              D3E is a tool for identifying differentially-expressed genes, based on single-cell RNA-seq data. D3E consists of two modules: one for identifying differentially expressed (DE) genes, and one for fitting the parameters of a Poisson-Beta distribution.
            '';
            license = licenses.gpl3;
            #maintainers = with maintainers; [ AndersonTorres ];
            platforms = platforms.unix;
          };
        }
    );
  };
}
