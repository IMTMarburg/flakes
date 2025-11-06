{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      version_hashes = {
        "5.1" = "sha256-q6pqHpqN+QKkI/tAPdLXqFo893BqtK4JnkpM+w5iGxI=";
        "4.11.1" = "sha256-gNHNAGFnKYlAF7JKNqLvgfnN6L02Toda6tHgz7UAyCs=";
      };

      configfile = pkgs.writeText "homer-config.txt" ''
        # Homer Configuration File (automatically generated)
        #
        # This file is updated from the Homer website and contains information about data available for
        # use with the program.
        #
        # Each section has the same format, which is <tab> separated values specifying:
        # package name <tab> version <tab> description <tab> url <tab> optional parameters (, separated)
        #
        SOFTWARE
        homer	v5.1	Code/Executables, ontologies, motifs for HOMER	http://homer.ucsd.edu/homer/data/software/homer.v5.1.zip	./	
        ORGANISMS
        PROMOTERS
        GENOMES
        SETTINGS
      '';

      homer =
        version:
        pkgs.stdenv.mkDerivation {
          pname = "homer";
          inherit version;

          src = pkgs.fetchurl {
            url = "http://homer.ucsd.edu/homer/data/software/homer.v${version}.zip";
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };

          buildInputs = [
            pkgs.unzip
            pkgs.gnutar
            pkgs.gcc
            pkgs.stdenv.cc.cc.lib
            pkgs.perl538
            pkgs.autoconf

          ];
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];

          unpackPhase = ''
            mkdir -p $out
            unzip $src -d $out
            rm $out/cpp/backup -r
            cp ${configfile} $out/config.txt
          '';

          buildPhase = ''
            perl $out/configureHomer.pl -make
          '';

          installPhase = ''
              # we need to fix the perl home paths in all the  scripts.
              # use lib "/gpfs/data01/cbenner/software/homer/.//bin";
              #sed -i "s|/gpfs/data01/cbenner/software/homer/|$out/|g" $out/bin/*.pl $out/update/*.pl $out/bin/*.pm $out/bin/old/*.pl $out/cpp/*.cpp
            # No additional installation steps needed as we already unzipped to $out
          '';

          meta = with pkgs.lib; {
            description = "HOMER: Software for Motif Discovery and Next-Gen Sequencing Analysis";
            homepage = "http://homer.ucsd.edu/homer/";
            license = licenses.gpl3Plus;
            maintainers = [ ];
            platforms = platforms.linux;
          };
        };
    in
    {
      packages.x86_64-linux.default = homer "5.1";
      packages.x86_64-linux.homer_4-11-1 = homer "4.11.1";

    };
}
