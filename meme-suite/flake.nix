{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";
  };

  outputs = { self, nixpkgs }: 
  let pkgs = import nixpkgs {system="x86_64-linux";}; in
  {
    defaultPackage.x86_64-linux = pkgs.callPackage ./default.nix {};

  };
}
