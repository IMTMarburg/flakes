{
  description = "Py-spy python profiler";

  inputs.nixpkgs.url = "nixpkgs/nixos-24.05";

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
      "7e76dd8b09562114998eb3cd967a7f893d8d9ab2" = "sha256-vV6eKQhK7y4G5865V7/NtSSWirbXmRxnlKSmO4Cr958=";
    };
  in rec {
    py-spy = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.rustPlatform.buildRustPackage rec {
        pname = "py-sy";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "benfred";
          repo = "py-spy";
          rev = version;
          sha256 = version_hashes.${version};
        };
        cargoSha256 = "sha256-DLAA3sYsFUrkxZOCrLc3izVIpKXbiNzADXgTHFm/+F8=";

        env.NIX_CFLAGS_COMPILE = "-L${pkgs.libunwind}/lib";
        checkFlags =
          [
            # thread 'python_data_access::tests::test_copy_string' panicked at 'called `Result::unwrap()` on an `Err`
            "--skip=python_data_access::tests::test_copy_string"
          ]
          ++ pkgs.lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
            # panicked at 'called `Result::unwrap()` on an `Err` value: failed to get os threadid
            "--skip=test_thread_reuse"
          ];

        nativeBuildInputs = [
          pkgs.rustPlatform.bindgenHook
        ];

        nativeCheckInputs = [
          pkgs.python3
        ];
      });

    defaultPackage = forAllSystems (system: (py-spy.${system} "7e76dd8b09562114998eb3cd967a7f893d8d9ab2"));
  };
}
