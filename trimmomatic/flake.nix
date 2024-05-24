{
  description = "flake for FASTQC";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    # Generate a user-friendly version number.
    #version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ]; # it's java afterall
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    version_hashes = {
      "0.39" = "sha256-u+ubmacwPy/vsEi0YQCv0fTnVDesQvqeQDEwCbS8M6I=";
    };
  in rec {
    # package.
    trimmomatic = forAllSystems (system: wanted_version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "trimmomatic";
        version = wanted_version;
        src = pkgs.fetchFromGitHub {
          owner = "usadellab";
          repo = "Trimmomatic";
          rev = "v${version}";
          sha256 = version_hashes.${version};
        };
        # Remove jdk version requirement
        postPatch = ''
          substituteInPlace ./build.xml \
            --replace 'source="1.5" target="1.5"' ""
        '';

        nativeBuildInputs = with pkgs; [jdk11_headless ant makeWrapper];

        buildPhase = ''
          runHook preBuild

          ant

          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin $out/share
          cp dist/jar/trimmomatic-${version}.jar $out/share/
          cp -r adapters $out/share/
          makeWrapper ${pkgs.jre}/bin/java $out/bin/trimmomatic \
            --add-flags "-cp $out/share/trimmomatic-${version}.jar org.usadellab.trimmomatic.Trimmomatic"

          runHook postInstall
        '';
        meta = let
          lib = pkgs.lib;
        in {
          changelog = "https://github.com/usadellab/Trimmomatic/blob/main/versionHistory.txt";
          description = "A flexible read trimming tool for Illumina NGS data";
          longDescription = ''
            Trimmomatic performs a variety of useful trimming tasks for illumina
            paired-end and single ended data: adapter trimming, quality trimming,
            cropping to a specified length, length filtering, quality score
            conversion.
          '';
          homepage = "http://www.usadellab.org/cms/?page=trimmomatic";
          downloadPage = "https://github.com/usadellab/Trimmomatic/releases";
          license = lib.licenses.gpl3Only;
          sourceProvenance = [
            lib.sourceTypes.fromSource
            lib.sourceTypes.binaryBytecode # source bundles dependencies as jars
          ];
          mainProgram = "trimmomatic";
        };
      });
    defaultPackage = forAllSystems (system: (trimmomatic.${system} "0.39"));
  };
}
