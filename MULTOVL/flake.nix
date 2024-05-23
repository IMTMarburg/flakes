{
  description = "Multiple Overlap of Genomic Regions";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.11"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    # Generate a user-friendly version number.
    #version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
      # "x86_64-darwin"
      # "aarch64-linux"
      # "aarch64-darwin"
    ]; #
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    revs = {
      "1.4beta" = "d42c5edc927d4b73d155153d4c8e0d41a92dcedf";
    };
    version_hashes = {
      #"1.9.0" = "sha256-gk/gnXIPEL6luEzwIBhZG75gTJHh9AGYYOl8Qz78pac=";
      "1.3-zenodo" = "sha256-mvxu7/p46N+yva3zWxaT8r7mRfVflbSGpM0eyagLYCo=";
      "1.4beta" = "sha256-1zhfb/9GrIQexEXwoNq9W04ENGARf3yhVOJapGwo6Zg=";
    };
  in rec {
    salmon = forAllSystems (
      system: version: let
        pkgs = nixpkgsFor.${system};
        boost = pkgs.boost174;
        buildInputs = [pkgs.cmake boost pkgs.zlib];
      in
        pkgs.stdenv.mkDerivation {
          pname = "multovl";
          version = version;
          src = pkgs.fetchFromGitHub {
            owner = "aaszodi";
            repo = "multovl";
            rev = revs.${version} or ("v" + version);
            sha256 = version_hashes.${version} or pkgs.lib.fakeSha256;
          };
          buildInputs = buildInputs;
          CXXFLAGS = "-std=c++11";
          configurePhase = ''
            cmake -DCMAKE_BUILD_TYPE=Release \
                      -DBOOST_ROOT=${pkgs.boost} \
                      -DBOOST_INCLUDE_DIR=${pkgs.boost}/include \
                      -DBOOST_LIBRARYDIR=${pkgs.boost.out}/lib \
                      -DMULTOVL_USE_STATIC_LIBS=OFF \
                      -DCMAKE_INSTALL_PREFIX=$out
          '';
          buildPhase = ''

            make -j $NIX_BUILD_CORES install
          '';
          postInstall = ''
              echo "patchelf!"
              entry=$out/multovl/1.4/lib/libbamtools.so.2.3.1
            ${pkgs.coreutils-full}/bin/md5sum $entry
              patchelf --set-rpath "${pkgs.lib.makeLibraryPath buildInputs}" $entry
            ${pkgs.coreutils-full}/bin/md5sum $entry
            mv $out/multovl/1.4/* $out
            rmdir $out/multovl/1.4
            rmdir $out/multovl
            #>cp $out/lib/*.so $out/bin

          '';
        }
    );
    defaultPackage = forAllSystems (system: (salmon.${system} "1.4beta"));
  };
}
