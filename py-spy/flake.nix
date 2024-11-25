{
  description = "Py-spy python profiler";

  inputs.nixpkgs.url = "nixpkgs/nixos-24.11";

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
      "593d6d8d26fddfe2287e36a673e4a8a9ba46ebcd" = "sha256-T96F8xgB9HRwuvDLXi6+lfi8za/iNn1NAbG4AIpE0V0=";
    };
  in rec {
    py-spy = forAllSystems (system: version: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.rustPlatform.buildRustPackage rec {
        pname = "py-py";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "benfred";
          repo = "py-spy";
          rev = version;
          sha256 = version_hashes.${version};
        };
        cargoHash = "sha256-nBvw9gKetX0x4boyp+h8SDpH0M0x8RhOEVsYeFWutnI=";

        env.NIX_CFLAGS_COMPILE = "-L${pkgs.libunwind}/lib";
        checkFlags =
          [
            # thread 'python_data_access::tests::test_copy_string' panicked at 'called `Result::unwrap()` on an `Err`
            "--skip=python_data_access::tests::test_copy_string"
          ]
          ++ pkgs.lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
            # panicked at 'called `Result::unwrap()` on an `Err` value: failed to get os threadid
            #"--skip=test_thread_reuse"
            "--skip=test_negative_linenumber_increment"
          ];

        nativeBuildInputs = [
          pkgs.rustPlatform.bindgenHook
        ];

        nativeCheckInputs = [
          pkgs.python3
        ];
      });

    defaultPackage = forAllSystems (system: (py-spy.${system} "593d6d8d26fddfe2287e36a673e4a8a9ba46ebcd"));
  };
}
