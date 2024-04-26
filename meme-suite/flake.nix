{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";
  };

  outputs = { self, nixpkgs }: 
  let pkgs = import nixpkgs {system="x86_64-linux";}; in
  {
    packages.x86_64-linux.default = pkgs.callPackage ./default.nix {};

  };
}
