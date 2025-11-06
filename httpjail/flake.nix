{
  description = "A Nix flake for httpjail - Monitor and restrict HTTP/HTTPS requests from processes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, naersk }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        naersk' = pkgs.callPackage naersk { };

      in
      {
        packages.default = naersk'.buildPackage {
          src = pkgs.fetchFromGitHub {
            owner = "coder";
            repo = "httpjail";
            rev = "81f78c492ae9adfec26462ca26515e2e4f2dea9e";
            hash = "sha256-BPxIetftv9Vxa5SHQl5NYWfQHV19HJcJX9l5Wvx4YtE=";
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            rustPlatform.bindgenHook
            python3
            gn
            ninja
          ];

          buildInputs = with pkgs; [
            openssl
          ] ++ lib.optionals stdenv.isLinux [
            glibc
          ] ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

          # Environment variables for build
          OPENSSL_NO_VENDOR = "1";
          
          # Allow network access during build for V8
          __noChroot = true;

          meta = with pkgs.lib; {
            description = "Monitor and restrict HTTP/HTTPS requests from processes";
            homepage = "https://github.com/coder/httpjail";
            license = licenses.cc0;
            maintainers = [ ];
            platforms = platforms.unix;
            # Note: This package requires network access during build due to V8 dependency
            # Consider using `nix build --option sandbox false` if build fails
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
            rustPlatform.bindgenHook
            python3
            gn
            ninja
          ];
          
          buildInputs = with pkgs; [
            openssl
          ] ++ lib.optionals stdenv.isLinux [
            glibc
          ] ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

          OPENSSL_NO_VENDOR = "1";
          
          shellHook = ''
            echo "httpjail development environment"
            echo "Note: V8 dependency may require network access during build"
            echo "Run 'nix build --option sandbox false' if needed"
          '';
        };

        # Make httpjail available as an app
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/httpjail";
        };
      });
}