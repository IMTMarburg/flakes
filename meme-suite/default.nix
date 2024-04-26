{
  lib,
  stdenv,
  fetchurl,
  python3,
  perl,
  zlib,
  perlPackages,
  makeWrapper,
}: let
  buildPerlPackage = perlPackages.buildPerlPackage;
  TestSysInfo = buildPerlPackage {
    pname = "Test-Sys-Info";
    version = "0.23";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BU/BURAK/Test-Sys-Info-0.23.tar.gz";
      hash = "sha256-MMXyxM/ujhrm2ftikfea3b/1c5uk76Wx4DRSDxj7yVo=";
    };
    meta = {
      description = "Centralized test suite for Sys::Info";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
  };
  TextTemplateSimple = buildPerlPackage {
    pname = "Text-Template-Simple";
    version = "0.91";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BU/BURAK/Text-Template-Simple-0.91.tar.gz";
      hash = "sha256-9fZnjlSH3projIcpYmnYp9Q+/3Kyid4AoOvWRJXhGaw=";
    };
    meta = {
      description = "Simple text template engine";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
  };
  SysInfoBase = buildPerlPackage {
    pname = "Sys-Info-Base";
    version = "0.7807";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BU/BURAK/Sys-Info-Base-0.7807.tar.gz";
      hash = "sha256-EyNisARujcTxLhVgkDYjqIqIcdCb8cKdk9SNP0pYKss=";
    };
    propagatedBuildInputs = [TextTemplateSimple];
    meta = {
      description = "Base class for Sys::Info";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
  };

  SysInfo = buildPerlPackage {
    pname = "Sys-Info";
    version = "0.7811";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BU/BURAK/Sys-Info-0.7811.tar.gz";
      hash = "sha256-VmSCv/NCfBmNeVVGjtlFqOc2xKKSUVH975aAHvikAeE=";
    };
    buildInputs = [TestSysInfo];
    propagatedBuildInputs = [SysInfoBase];
    meta = {
      description = "Fetch information from the host system";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
    checkPhase = ":";
    doCheck = false;
  };
  PodUsage = buildPerlPackage {
    pname = "Pod-Usage";
    version = "2.03";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MA/MAREKR/Pod-Usage-2.03.tar.gz";
      hash = "sha256-fY/cfc5gCHts+eSTuNauhKWrTAYIqAam05XMZVdGB0Q=";
    };
    meta = {
      homepage = "https://github.com/Dual-Life/Pod-Usage";
      description = "Extracts POD documentation and shows usage information";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
  };
  FileTemp = buildPerlPackage {
    pname = "File-Temp";
    version = "0.2311";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/File-Temp-0.2311.tar.gz";
      hash = "sha256-IpDWG/XDmIL8MxHanOHH9C29+CWuFp5VLFn+RZizb0o=";
    };
    meta = {
      homepage = "https://github.com/Perl-Toolchain-Gang/File-Temp";
      description = "Return name and handle of a temporary file safely";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
  };
  DataDumper = buildPerlPackage {
    pname = "Data-Dumper";
    version = "2.183";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NW/NWCLARK/Data-Dumper-2.183.tar.gz";
      hash = "sha256-5Cc2iQt9rhs3gY2cXvofH9xS3sBPRGozpIGb8dSrWtM=";
    };
    meta = {
      homepage = "http://dev.perl.org/";
      description = "Stringified perl data structures, suitable for both printing and C<eval>";
      license = with lib.licenses; [artistic1 gpl1Plus];
    };
  };
  myperl = with perlPackages;
    makePerlPath [
      XMLSimple
      XMLParser
      SysInfo
      ScalarListUtils
      ListAllUtils
      PodUsage
      JSON
      HTMLTree
      HTMLTemplate
      GetoptLong
      FileTemp
      PathTools
      DataDumper
    ];
in
  stdenv.mkDerivation rec {
    pname = "meme-suite";
    version = "5.5.5";

    src = fetchurl {
      url = "https://meme-suite.org/meme-software/${version}/meme-${version}.tar.gz";
      sha256 = "sha256-vrtKF25y1i46LVul8iQ5GFu8S79HaWBPvKEt/44fc58=";
    };

    buildInputs = [zlib];
    nativeBuildInputs = [perl python3 makeWrapper];
    postFixup = ''
      wrapProgram $out/bin/meme-chip --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/ama-qvalues --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/beeml2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/centrimo-plots --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/chen2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/dreme_xml_to_html --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/dreme_xml_to_txt --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/elm2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-center --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-fetch --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-grep --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-make-index --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-most --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-re-match --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-subsample --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/fasta-unique-names --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/hart2meme-bkg --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/hartemink2psp --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/iupac2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/jaspar2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/mast_xml_to_html --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/mast_xml_to_txt --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/matrix2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/meme-chip_html_to_tsv --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/meme-rename --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/meme_xml_to_html --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/nmica2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/priority2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/prosite2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/psp-gen --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/rna2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/rsat-retrieve-seq --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/rsat-supported-organisms --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/scpd2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/simplepp --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/sites2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/streme_xml_to_html --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/taipale2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/tamo2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/tomtom_xml_to_html --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/transfac2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/uniprobe2meme --prefix PERL5LIB : "${myperl}"
      wrapProgram $out/libexec/meme-${version}/xstreme_html_to_tsv --prefix PERL5LIB : "${myperl}"
    '';

    meta = with lib; {
      description = "Motif-based sequence analysis tools";
      #license = licenses.unfree;  # which I could do this differently, but the unfree handling in flakes is broken.
      maintainers = with maintainers; [gschwartz];
      platforms = platforms.linux;
    };
  }
