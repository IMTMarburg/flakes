{
  description = "SAILOR 1.0.4 (RNA editing detection) as a Singularity/Apptainer image, built with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sailor-src = {
      # 1.0.4 layout (CWL-SINGULARITY-pipeline-building-code/); master has moved on to 1.2.x
      url = "github:YeoLab/sailor/9a57b4b7a62cea9149d99ec3b186dec26cfc315b";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, sailor-src }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      version = "1.0.4";

      # Exact conda packages of the working micromamba-built image.
      # The original conda_environment.yaml no longer resolves, so these are pinned
      # by URL + hash instead of being solved:
      #   conda: python 2.7.12, numpy 1.10.4, pandas 0.17.1, scipy 0.16.1, pysam 0.8.4pre0
      #   tools: samtools 1.3.1, bcftools 1.2 (newer samtools lack 'mpileup -g' and 'rmdup')
      condaLock = lib.importJSON ./conda-packages.json;

      installerPython = pkgs.python3.withPackages (ps: [ ps.zstandard ]);

      # Builds a conda env whose files expect to live at `prefix` inside the image.
      # This is a plain runCommand (no fixup phase), so shebangs and ELF files keep
      # their conda paths and get no Nix store references.
      mkCondaEnv =
        name: prefix:
        let
          tarballs = map (p: pkgs.fetchurl { inherit (p) url hash; }) condaLock.${name};
        in
        pkgs.runCommand "sailor-conda-${name}" { } ''
          ${installerPython}/bin/python3 ${./conda-install.py} $out ${prefix} ${lib.escapeShellArgs tarballs}
        '';

      condaEnv = mkCondaEnv "conda" "/opt/conda";
      toolsEnv = mkCondaEnv "tools" "/opt/tools";

      # Userland for the scripts in bin/. cwltool comes from nixpkgs too; a modern one runs
      # the cwlVersion v1.0 workflow fine (the original image used one as well).
      baseEnv = pkgs.buildEnv {
        name = "sailor-base";
        paths = with pkgs; [
          bashInteractive
          coreutils
          findutils
          diffutils
          gnugrep
          gnused
          gawk
          gnutar
          gzip
          which
          less
          procps
        ];
      };

      runPath = "/opt/sailor/bin:/opt/sailor/cwl:/opt/sailor/py:/opt/conda/bin:/opt/tools/bin:/usr/bin:/bin";

      singularityD = pkgs.runCommand "sailor-singularity-d" { } ''
        d=$out/.singularity.d
        mkdir -p $d/actions $d/env $d/libs

        cat > $d/env/01-base.sh <<'EOF'
        #!/bin/sh
        EOF

        cat > $d/env/90-environment.sh <<'EOF'
        #!/bin/sh
        export PATH="${runPath}"
        export LANG="''${LANG:-C.UTF-8}"
        export LC_ALL="''${LC_ALL:-C.UTF-8}"
        EOF

        cat > $d/env/99-base.sh <<'EOF'
        #!/bin/sh
        if [ -z "$LD_LIBRARY_PATH" ]; then
            LD_LIBRARY_PATH="/.singularity.d/libs"
        else
            LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/.singularity.d/libs"
        fi
        PS1="Singularity> "
        export LD_LIBRARY_PATH PS1
        EOF

        cat > $d/env/99-runtimevars.sh <<'EOF'
        #!/bin/sh
        if [ -n "''${SING_USER_DEFINED_PREPEND_PATH:-}" ]; then
            PATH="''${SING_USER_DEFINED_PREPEND_PATH}:''${PATH}"
        fi
        if [ -n "''${SING_USER_DEFINED_APPEND_PATH:-}" ]; then
            PATH="''${PATH}:''${SING_USER_DEFINED_APPEND_PATH}"
        fi
        if [ -n "''${SING_USER_DEFINED_PATH:-}" ]; then
            PATH="''${SING_USER_DEFINED_PATH}"
        fi
        unset SING_USER_DEFINED_PREPEND_PATH SING_USER_DEFINED_APPEND_PATH SING_USER_DEFINED_PATH
        export PATH
        EOF

        for a in exec run shell test start; do
          {
            echo '#!/bin/sh'
            [ $a = start ] && echo 'kill -CONT 1'
            echo 'for script in /.singularity.d/env/*.sh; do'
            echo '    if [ -f "$script" ]; then . "$script"; fi'
            echo 'done'
          } > $d/actions/$a
        done
        echo 'exec "$@"' >> $d/actions/exec
        echo 'exec /.singularity.d/runscript "$@"' >> $d/actions/run
        echo 'test -x /.singularity.d/startscript && exec /.singularity.d/startscript' >> $d/actions/start
        echo 'exec /.singularity.d/test "$@"' >> $d/actions/test
        cat >> $d/actions/shell <<'EOF'
        if test -n "$SINGULARITY_SHELL" -a -x "$SINGULARITY_SHELL"; then
            exec $SINGULARITY_SHELL "$@"
        fi
        SHELL=/bin/bash
        PS1="Singularity $SINGULARITY_NAME:\\w> "
        export SHELL PS1
        exec /bin/bash --norc "$@"
        EOF

        cat > $d/runscript <<'EOF'
        #!/bin/sh
        exec /opt/sailor/runscript.sh "$@"
        EOF

        cat > $d/startscript <<'EOF'
        #!/bin/sh
        EOF

        cat > $d/test <<'EOF'
        #!/bin/sh
        set -e
        python -c "import pysam, pandas, scipy; print pysam.__version__"
        samtools 2>&1 | grep Version
        bcftools 2>&1 | grep Version
        cwltool --version
        EOF

        cat > $d/labels.json <<'EOF'
        {
          "org.label-schema.schema-version": "1.0",
          "org.label-schema.name": "sailor",
          "org.label-schema.version": "${version}",
          "org.label-schema.vcs-url": "https://github.com/YeoLab/sailor",
          "org.label-schema.vcs-ref": "${sailor-src.rev or "unknown"}",
          "org.label-schema.build-arch": "amd64"
        }
        EOF

        chmod 755 $d/actions/* $d/env/*.sh $d/runscript $d/startscript $d/test
        ln -s .singularity.d/actions/exec $out/.exec
        ln -s .singularity.d/actions/run $out/.run
        ln -s .singularity.d/actions/shell $out/.shell
        ln -s .singularity.d/actions/test $out/.test
        ln -s .singularity.d/runscript $out/singularity
      '';

      # The image's root filesystem as a directory tree (also handy for inspection
      # or as an apptainer sandbox).
      rootfs =
        let
          closure = pkgs.closureInfo {
            rootPaths = [
              baseEnv
              pkgs.glibc
              pkgs.stdenv.cc.cc.lib
              pkgs.libxcrypt-legacy
              pkgs.cacert
              pkgs.cwltool
            ];
          };
          up = "${sailor-src}/CWL-SINGULARITY-pipeline-building-code";
          data = "${sailor-src}/tests/data";
        in
        pkgs.runCommand "sailor-${version}-rootfs" { } ''
          mkdir -p $out
          cd $out

          # the Nix store closure the image's userland points into
          mkdir -p nix/store
          xargs -I{} cp -a {} nix/store/ < ${closure}/store-paths

          # FHS-ish skeleton: conda binaries expect /lib64/ld-linux-x86-64.so.2,
          # the Nix ld.so finds its own glibc from there
          mkdir -p bin usr/bin lib64 etc/ssl/certs tmp var/tmp root home mnt srv proc sys dev run
          chmod 1777 tmp var/tmp
          for f in ${baseEnv}/bin/*; do
            ln -s "$f" bin/
            ln -s "$f" usr/bin/
          done
          ln -sf ${baseEnv}/bin/bash bin/sh
          ln -s ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
          ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
          ln -s ca-certificates.crt etc/ssl/certs/ca-bundle.crt
          # bind targets for apptainer
          touch etc/passwd etc/group etc/hosts etc/resolv.conf etc/localtime
          echo 'root:x:0:0:root:/root:/bin/sh' > etc/passwd
          echo 'root:x:0:' > etc/group

          # conda envs
          mkdir -p opt
          cp -a ${condaEnv} opt/conda
          cp -a ${toolsEnv} opt/tools
          # Runtime libs the env took from the distro base image (micromamba's debian):
          # pandas/scipy need libstdc++/libgcc_s, python's crypt module libcrypt.so.1.
          # Nix's ld.so doesn't search /usr/lib, so put them on the env's RPATH.
          chmod u+w opt/conda/lib
          ln -s ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 opt/conda/lib/
          ln -s ${pkgs.stdenv.cc.cc.lib}/lib/libgcc_s.so.1 opt/conda/lib/
          ln -s ${pkgs.libxcrypt-legacy}/lib/libcrypt.so.1 opt/conda/lib/
          chmod u-w opt/conda/lib

          # sailor itself (upstream repo)
          mkdir -p opt/sailor
          cp -r ${up}/bin ${up}/cwl ${up}/py opt/sailor/
          cp ${up}/singularity opt/sailor/runscript.sh
          cp -r ${up}/documentation documentation
          chmod -R u+w opt/sailor documentation
          # nixpkgs wraps cwltool with PATH=<its python3 deps>:$PATH, and cwltool hands
          # PATH on to the tools, so "#!/usr/bin/env python" would find python3. The
          # wrapped script sets up its own sys.path, so use it directly.
          test -x ${pkgs.cwltool}/bin/.cwltool-wrapped
          ln -s ${pkgs.cwltool}/bin/.cwltool-wrapped opt/sailor/bin/cwltool

          # example job + data, copied out by the runscript on request
          mkdir -p opt/sailor/example
          cp ${data}/ce11.chrI.fa opt/sailor/example/ce11.chrI.fa
          cp ${data}/example.single_end.bam opt/sailor/example/ce11_example_single_end.bam
          cp ${data}/ce11_knownSNPs.bed opt/sailor/example/ce11_known_SNPs.bed
          cp ${./example/ce11_example.yaml} opt/sailor/example/ce11_example.yaml

          chmod -R u+w opt/sailor/example
          chmod 755 opt/sailor/bin/sailor opt/sailor/bin/ifnotskip opt/sailor/py/*.py opt/sailor/runscript.sh

          cp -a ${singularityD}/. .
        '';

      sif = pkgs.runCommand "sailor-${version}.sif"
        {
          nativeBuildInputs = [
            pkgs.squashfsTools
            pkgs.apptainer
          ];
        }
        ''
          mksquashfs ${rootfs} rootfs.squashfs \
            -noappend -all-root -no-xattrs -comp gzip \
            -processors $NIX_BUILD_CORES -quiet
          export HOME=$TMPDIR
          apptainer sif new image.sif
          apptainer sif add image.sif rootfs.squashfs \
            --datatype 4 --parttype 2 --partfs 1 --partarch 2 --groupid 1
          mv image.sif $out
          chmod 755 $out
        '';
      # result/bin/sailor: runs the image. Prefers the host's singularity/apptainer
      # (setuid installs, site config); falls back to nixpkgs' unprivileged apptainer.
      wrapper = pkgs.writeShellScriptBin "sailor" ''
        if [ -n "''${SAILOR_CONTAINER_RUNTIME:-}" ]; then
          runtime="$SAILOR_CONTAINER_RUNTIME"
        elif command -v singularity > /dev/null; then
          runtime=singularity
        elif command -v apptainer > /dev/null; then
          runtime=apptainer
        else
          runtime=${pkgs.apptainer}/bin/apptainer
        fi
        exec "$runtime" run ${sif} "$@"
      '';

      sailor = pkgs.runCommand "sailor-${version}" { meta.mainProgram = "sailor"; } ''
        mkdir -p $out/bin $out/share/sailor
        ln -s ${wrapper}/bin/sailor $out/bin/sailor
        ln -s ${sif} $out/share/sailor/sailor-${version}.sif
      '';
    in
    {
      apps.${system}.default = {
        type = "app";
        program = "${sailor}/bin/sailor";
      };

      packages.${system} = {
        default = sailor;
        inherit sailor sif;
        inherit rootfs condaEnv toolsEnv baseEnv;
      };
    };
}
