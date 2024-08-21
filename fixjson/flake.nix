{
  description = "FixJSON read json5 and turn it into json";
  # why don't we just add it to the python packages?
  # because we want it to be independent of our python packages / python version
  # (e.g. MACS2 2.2.7.1 is (trivially) not python 3.10 compatible,
  # because they cast the version to a float and compare to <3.6

  inputs = {nixpkgs.url = "nixpkgs/nixos-24.05";};

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
        fixjson = pkgs.buildNpmPackage rec {
          pname = "fixjson";
          version = "1.1.2";
          src = pkgs.fetchFromGitHub {
            owner = "rhysd";
            repo = pname;
            rev = "c49f27a0268fca69021fa8aafc9bbef9960f82e9";
            hash = "sha256-Hse2EBppeEBoMQjRI97MNYWlRDpoOMhkZ/nbhpFgH5c=";
          };
          npmDepsHash = "sha256-mreSdJxFjSaz3kNoFC5ZSlBENA2sOLmsxS0VKW4o0z4=";
        };
      in
        fixjson
    );
  };
}
