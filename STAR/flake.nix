{
  description = "STAR aligner";

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
      "2.7.3a" = "sha256-WO59Zyg7eAJ+MmRNgX0XQFmRmmMw/q96YBdoiAvH8cE=";
      "2.7.9a" = "sha256-p1yaIbSGu8K5AkqJj0BAzuoWsXr25eCNoQmLXYQeg4E=";
      "2.7.10a" = "sha256-qwddCGMOKWgx76qGwRQXwvv9fCSeVsZbWHmlBwEqGKE=";
      "2.7.11b" = "sha256-4EoS9NOKUwfr6TDdjAqr4wGS9cqVX5GYptiOCQpmg9c=";
    };
  in rec {
    star = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.star.overrideAttrs (oldAttrs: {
        version = version;
        src = pkgs.fetchFromGitHub {
          repo = "STAR";
          owner = "alexdobin";
          rev = version;
          sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
        };
        nativeBuildInputs =
          (oldAttrs.nativeBuildInputs or [])
          ++ (
            if version >= "2.7.11b"
            then [pkgs.unixtools.xxd]
            else []
          );
      }));
    defaultPackage = forAllSystems (system: (star.${system} "2.7.11b"));
  };
}
