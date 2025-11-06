# this is failing because of v8 rust.. i think we can steal this from Deno?
{
  description = "Hashcards - anki cards in terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    naersk,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      naersk' = pkgs.callPackage naersk {};
    in {
      packages.default = naersk'.buildPackage {
        src = pkgs.fetchFromGitHub {
          owner = "eudoxia0";
          repo = "hashcards";
          rev = "10fcb6f7b9c4df637b6e7340bb4a7ab33b3c597d";
          hash = pkgs.lib.fakeSha256;
        };

        nativeBuildInputs = with pkgs; [
          pkg-config
          rustPlatform.bindgenHook
          gn
          ninja
        ];

        buildInputs = with pkgs;
          [
            openssl
          ]
          ++ lib.optionals stdenv.isLinux [
            glibc
          ]
          ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        # Environment variables for build
        OPENSSL_NO_VENDOR = "1";

        meta = with pkgs.lib; {
          description = "A plain text-based spaced repetition system";
          homepage = "https://github.com/eudoxia0/hashcards";
          license = licenses.apache20;
          maintainers = [];
          platforms = platforms.unix;
        };
      };

      # Make httpjail available as an app

      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/hashcard";
      };
    });
}
