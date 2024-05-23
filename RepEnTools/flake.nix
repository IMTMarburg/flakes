{
  description = "RepEnTools - analysis of ChIPseq for repetitive elements";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11"; # I'm pretty sure it will start failing once pands is newer than 1.5.x
  inputs.subread.url = "github:/IMTMarburg/flakes?dir=Subread";
  inputs.subread.inputs.nixpkgs.follows = "nixpkgs";
  inputs.fastqc.url = "github:/IMTMarburg/flakes?dir=FASTQC";
  inputs.fastqc.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    subread,
    fastqc,
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
        mypython = pkgs.python311.withPackages (ps: with ps; [pandas numpy scipy matplotlib seaborn]);
        src_truseq = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/usadellab/Trimmomatic/main/adapters/TruSeq3-PE.fa";
        };
        subread_pkg = subread.defaultPackage.${system};
        fastqc_pkg = fastqc.defaultPackage.${system};
      in
        pkgs.stdenv.mkDerivation {
          pname = "RepEnTools";
          version = "1.1";
          src = pkgs.fetchFromGitHub {
            owner = "PavelBashtrykov";
            repo = "RepEnTools";
            rev = "c447dda3d6edc607d0c18d94a33b121101040cbc";
            sha256 = "sha256-u0/9HlnW088L4+KBjBG2E2DwOClSRb7/++d5R651qbo=";
          };
          buildInputs = [mypython pkgs.trimmomatic pkgs.hisat2 subread_pkg pkgs.samtools fastqc_pkg pkgs.wget pkgs.unzip];
          installPhase = ''
            mkdir -p $out/bin
            cp ret $out/bin
            cp getdata $out/bin
            cp compute_enrichment.py $out/bin
            cp plot_enrichment.py $out/bin
            chmod +x $out/bin/*
            patchShebangs $out/bin/*

            substituteInPlace $out/bin/ret --replace "source ~/miniconda3/etc/profile.d/conda.sh" "export REPENTOOLS_DIR=\"$out/bin\"" \
               --replace "conda deactivate" "#conda deactivate"  \
               --replace "conda activate" "#conda deactivate" \
               --replace "fastqc " "${fastqc_pkg}/bin/fastqc " \
               --replace "trimmomatic" "${pkgs.trimmomatic}/bin/trimmomatic" \
               --replace "hisat2" "${pkgs.hisat2}/bin/hisat2" \
               --replace "samtools" "${pkgs.samtools}/bin/samtools" \
               --replace "featureCounts" "${subread_pkg}/bin/featureCounts" \
               --replace "rm $\{MAIN_DIR}/$\{TAG}_multiple_feature_counts.txt" ""
          '';
          postInstall = ''
            mkdir $out/adapters
            cp $src_truseq $out/adaptersA/TruSeq3-PE.fa
          '';
          meta = with pkgs.lib; {
            homepage = "https://github.com/PavelBashtrykov/RepEnTools";
            description = "RepEnTools: genome-wide repeat element enrichment analysis in ChIP-seq data or similar ";
            longDescription = ''
              RepEnTools is a software package for genome-wide repeat element (RE) enrichment analysis in ChIP-seq data or similar.

              Paper: https://link.springer.com/article/10.1186/s13100-024-00315-y
            '';
            license = licenses.gpl3;
            #maintainers = with maintainers; [ AndersonTorres ];
            platforms = platforms.unix;
          };
        }
    );
  };
}
