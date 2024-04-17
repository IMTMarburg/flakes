{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-23.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
    jinja_partials = pkgs.python310Packages.buildPythonPackage rec {
      pname = "jinja_partials";
      version = "0.2.1";
      src = pkgs.fetchPypi {
        inherit pname version;
        sha256 = "sha256-WzLMA17pPzct387PlsSDdFDYVh0OL/JsidwNC9BxEos=";
      };
      patches = [./jinja_partials.patch];
      propagatedBuildInputs = with pkgs.python310Packages; [pip jinja2];
    };
  in {
    packages.x86_64-linux.default = pkgs.python310Packages.buildPythonApplication {
      name = "CRISPResso2";
      src = pkgs.fetchFromGitHub {
        owner = "pinellolab";
        repo = "CRISPResso2";
        rev = "v2.3.0";
        sha256 = "sha256-KrYZ7Q2ymWbh4LmQ+Rkg3CIJ3LIL7Mvp1N9ZLSHOdAU=";
      };

      propagatedBuildInputs = with pkgs.python310Packages; [numpy cython jinja2 pyparsing scipy matplotlib pandas plotly setuptools jinja_partials seaborn];
      doCheck = false;
      buildInputs = [
        pkgs.bowtie2
        pkgs.samtools
        pkgs.perl538Packages.SysHostnameLong
        pkgs.fastp
        pkgs.tbb
      ];
    };
  };
}
