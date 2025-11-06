{
  description = "Subread aligner";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.05"; # doesn't matter much

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
      "2.11" = "sha256-2AjrWxgjxXLLRal8laPFrLPY4pqkfsdOPKHrNFeHwxs=";
    };
  in rec {
    pandaseq = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.stdenv.mkDerivation rec {
        pname = "Pandaseq";
        inherit version;
        src = pkgs.fetchFromGithub {
          owner = "neufeld";
          repo = "pandaseq";
          rev = "v2.11";

          sha256 = version_hashes.${version};
        };
        nativeBuildInputs = with pkgs; [zlib];
        # sourceRoot = "subread-${version}-source/src";
        # buildPhase = ''
        #   make -f Makefile.Linux
        # '';
        # installPhase = ''
        #   mkdir $out/bin -p
        #   cp ../bin/* $out/bin/ || true
        # '';
      });
    defaultPackage = forAllSystems (system: (pandaseq.${system} "2.11"));
  };
}
