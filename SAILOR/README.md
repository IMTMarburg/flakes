# sailor-flake

Nix builds of the SAILOR Singularity/Apptainer image (YeoLab/sailor, the
`CWL-SINGULARITY-pipeline-building-code/` layout), for two releases:

| release | upstream commit | outputs |
|---|---|---|
| 1.2.0 (default) | `ac365af` (tag `v1.2.0`) | `sailor-1_2_0`, `sif-1_2_0`, `rootfs-1_2_0` |
| 1.0.4 | `9a57b4b` | `sailor-1_0_4`, `sif-1_0_4`, `rootfs-1_0_4` |

1.2.0 adds the `ct` / `gt` job options (C>T and G>T edits instead of A>G).
Both use the same conda envs. Upstream 1.2.0's `bin/sailor` still writes a
`SAILOR-VERSION.1.0.4` marker file into the job directory; that's upstream.

```sh
nix build                      # -> result/bin/sailor (1.2.0), runs the image
result/bin/sailor              # usage + offer to copy the example job
result/bin/sailor job.yaml
nix run . -- job.yaml          # same thing via the app output
nix run .#sailor-1_0_4 -- job.yaml

nix build .#sif-1_2_0          # just the SIF
nix build .#rootfs-1_2_0       # the same tree as a directory (apptainer sandbox / inspection)
```

`bin/sailor` runs `singularity run <sif> "$@"`. It uses `singularity` or
`apptainer` from `PATH` if one is there, and falls back to nixpkgs' apptainer
otherwise. Set `SAILOR_CONTAINER_RUNTIME` to force a runtime. The SIF is also
at `result/share/sailor/sailor-<version>.sif`.

## What's in the image

| path | from |
|---|---|
| `/opt/conda` | python 2.7.12, numpy 1.10.4, pandas 0.17.1, scipy 0.16.1, pysam 0.8.4pre0 (conda) |
| `/opt/tools` | samtools 1.3.1, bcftools 1.2 (conda; newer samtools dropped `mpileup -g` / `rmdup`) |
| `/opt/sailor/{bin,cwl,py}`, `/documentation` | upstream repo |
| `/opt/sailor/bin/cwltool` | nixpkgs cwltool (modern, runs the v1.0 workflow) |
| `/opt/sailor/example` | 1.2.0: upstream `example/`; 1.0.4: the same files built from `tests/data` + `example/ce11_example.yaml` |
| `/bin`, `/usr/bin`, `/nix/store` | bash, coreutils & friends from nixpkgs |

The original `conda_environment.yaml` no longer resolves, so there is no conda
solve at build time. `conda-packages.json` pins the exact package URLs and
hashes of the last micromamba-built image that worked. `conda-install.py`
unpacks them offline and rewrites the conda prefix placeholders to
`/opt/conda` and `/opt/tools`. The resulting envs are byte-identical to the
micromamba-built ones, and the example job's outputs match the old image's
(apart from `##` VCF header lines that contain file names and commands).

Glue between the conda binaries and Nix:
- `/lib64/ld-linux-x86-64.so.2` points to the Nix glibc loader.
- `libstdc++`, `libgcc_s` and `libcrypt.so.1` are symlinked into
  `/opt/conda/lib`. The Debian base image used to provide them.
- cwltool is the unwrapped `.cwltool-wrapped` script. The nixpkgs wrapper
  would put python3 ahead of `/opt/conda/bin` on the tools' `PATH`.

The `.sif` is not bit-reproducible, because `apptainer sif new` stamps a
random UUID and the current time into the header.
