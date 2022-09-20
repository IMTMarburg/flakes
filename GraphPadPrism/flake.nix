{
  description = "Graphad prism";
  # wrap prism in a 'wine bottle' that does the install and so on on first start
  # not pretty, not prebuild, but it does work...

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05"; # doesn't matter much

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
    ]; # 
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    defaultPackage = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        mkWindowsApp = pkgs.callPackage ./mkWindowsApp {makeBinPath = pkgs.lib.makeBinPath;};

        srcs = {
          win64 = pkgs.fetchurl {
            url = "https://cdn.graphpad.com/downloads/prism/9/InstallPrism9.msi";
            sha256 = "sha256-ADCPLp7oMZxRXHKEzlGLNKPTRrr4BY4tP+c9r0KwNgk=";
          };
        };
        wine = pkgs.wine;
        wineArch = "win64";
      in
        mkWindowsApp rec
        {
          pname = "Graphpad-Prism";
          version = "9";
          wine = pkgs.wineWowPackages.stable;
          inherit wineArch;
          src = srcs.${wineArch};

          winAppRun = ''
            export WINE="${pkgs.wineWowPackages.stable}/bin/wine";
            wine start /unix "$WINEPREFIX/drive_c/Program Files/GraphPad/Prism 9/prism.exe" "$ARGS"
            Program Files/GraphPad/Prism 9
          '';

          winAppInstall = ''
            export WINE="${pkgs.wineWowPackages.stable}/bin/wine";
            echo "winAppInstall ${src} copy!"
            cp ${src} "$WINEPREFIX/drive_c/install.msi"
            echo msiexec  /i c:\\install.msi
            wine start msiexec /QUIET /i c:\\install.msi STARTPRISM=0
            wineserver -w
            echo "Wine server returned"
            winetricks gdiplus msxml6 corefonts
            rm "$WINEPREFIX/drive_c/install.msi" -f
          '';

          installPhase = ''
            runHook preInstall
            ln -s $out/bin/.launcher $out/bin/graphpad_prism

            runHook postInstall
          '';

          #nativeBuildInputs = [copyDesktopItems];
          dontUnpack = true;
        }
    );
  };
}
