{
  description = "flake for FASTQC";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # doesn't matter much

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
      "0.11.9" = "sha256:1hlgvms3l4a2vrdgl3j99dvg19m0h5yclc5xzqgizy1qrm7m51mv";
      "0.12.0" = "sha256:1hxgvms3l4a2vrdgl3j99dvg19m0h5yclc5xzqgizy1qrm7m51mv";
    };
  in rec {
    # package.
    fastqc = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "FASTQC";
        version = "0.11.9";
        src = fetchTarball {
          url = "https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v${version}.zip";
          sha256 = "sha256:1hlgvms3l4a2vrdgl3j99dvg19m0h5yclc5xzqgizy1qrm7m51mv";
        };
        nativeBuildInputs = with pkgs; [jdk perl];
        buildPhase = "";
        installPhase = ''
          ls
            mkdir $out/FASTQC -p
            cp * $out/FASTQC -r
            chmod +x $out/FASTQC/fastqc
            mkdir $out/bin -p
            substituteInPlace $out/FASTQC/fastqc --replace '"java"' '"${pkgs.jdk}/bin/java"'
            cd $out/bin && ln -s $out/FASTQC/fastqc
        '';
      });
    defaultPackage = forAllSystems (system: (fastqc.${system} "0.12.0"));
  };
}
