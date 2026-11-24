#!/usr/bin/env python3
"""Minimal offline conda package installer.

Usage: conda-install.py TARGET_DIR FINAL_PREFIX PKG [PKG ...]

Unpacks each conda package (.tar.bz2 or .conda) into TARGET_DIR, then
rewrites the build-time prefix placeholders to FINAL_PREFIX (the path the
env will live at inside the image, e.g. /opt/conda), the same way
conda/micromamba do:

  * text mode:   plain string replacement
  * binary mode: replace inside NUL-terminated C strings and pad with NULs
                 so the file length and offsets stay the same

Writes conda-meta/<name>-<version>-<build>.json so the env looks like a
normal conda env from inside the container. No dependency solving, no
network: the package list is assumed to be complete (it is pinned in
conda-packages.json).
"""

import json
import os
import re
import shutil
import stat
import sys
import tarfile
import zipfile

import zstandard

DEFAULT_PLACEHOLDER = "/opt/anaconda1anaconda2anaconda3"


def extract_tar(fileobj, dest):
    with tarfile.open(fileobj=fileobj, mode="r|*") as tf:
        tf.extractall(dest, filter="tar")


def extract_package(path, dest):
    if path.endswith(".conda"):
        with zipfile.ZipFile(path) as zf:
            for name in zf.namelist():
                if name.endswith(".tar.zst"):
                    with zf.open(name) as raw:
                        with zstandard.ZstdDecompressor().stream_reader(raw) as zr:
                            extract_tar(zr, dest)
    else:
        with open(path, "rb") as fh:
            extract_tar(fh, dest)


def prefix_entries(pkgdir):
    """Yield (relpath, placeholder, mode) for files needing prefix replacement."""
    paths_json = os.path.join(pkgdir, "info", "paths.json")
    if os.path.exists(paths_json):
        with open(paths_json) as fh:
            for p in json.load(fh)["paths"]:
                if "prefix_placeholder" in p:
                    yield p["_path"], p["prefix_placeholder"], p.get("file_mode", "text")
        return
    has_prefix = os.path.join(pkgdir, "info", "has_prefix")
    if os.path.exists(has_prefix):
        with open(has_prefix) as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                parts = line.split()
                if len(parts) == 1:
                    yield parts[0], DEFAULT_PLACEHOLDER, "text"
                else:
                    # "placeholder mode path" (path may not contain spaces in practice)
                    yield parts[2], parts[0], parts[1]


def replace_binary(data, placeholder, new_prefix):
    pat = re.compile(re.escape(placeholder) + rb"([^\0]*?)\0")

    def repl(m):
        out = m.group(0).replace(placeholder, new_prefix)
        padding = len(m.group(0)) - len(out)
        if padding < 0:
            raise ValueError("new prefix longer than placeholder")
        return out + b"\0" * padding

    return pat.sub(repl, data)


def install(pkg, target, final_prefix):
    tmp = os.path.join(target, ".pkg-tmp")
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    extract_package(pkg, tmp)

    with open(os.path.join(tmp, "info", "index.json")) as fh:
        index = json.load(fh)
    paths_json = os.path.join(tmp, "info", "paths.json")
    if os.path.exists(paths_json):
        with open(paths_json) as fh:
            files = [p["_path"] for p in json.load(fh)["paths"]]
    else:
        with open(os.path.join(tmp, "info", "files")) as fh:
            files = [l.rstrip("\n") for l in fh if l.strip()]

    for rel, placeholder, mode in prefix_entries(tmp):
        fn = os.path.join(tmp, rel)
        if os.path.islink(fn) or not os.path.exists(fn):
            continue
        with open(fn, "rb") as fh:
            data = fh.read()
        ph, new = placeholder.encode(), final_prefix.encode()
        if mode == "binary":
            new_data = replace_binary(data, ph, new)
        else:
            new_data = data.replace(ph, new)
        if new_data != data:
            st = os.stat(fn)
            os.chmod(fn, st.st_mode | stat.S_IWUSR)
            with open(fn, "wb") as fh:
                fh.write(new_data)
            os.chmod(fn, st.st_mode)

    # The only post-link script in the pinned set: pkgs/free openssl 1.0.x runs
    # bin/.openssl-libcrypto-fix, which swaps a '/opt/aaaa...' placeholder in
    # libcrypto for the prefix. Same thing, without running the script.
    if os.path.exists(os.path.join(tmp, "bin", ".openssl-libcrypto-fix")):
        fn = os.path.join(tmp, "lib", "libcrypto.so.1.0.0")
        with open(fn, "rb") as fh:
            data = fh.read()
        ph = re.search(rb"/opt/a{100,}", data).group(0)
        new_data = replace_binary(data, ph, final_prefix.encode())
        st = os.stat(fn)
        os.chmod(fn, st.st_mode | stat.S_IWUSR)
        with open(fn, "wb") as fh:
            fh.write(new_data)
        os.chmod(fn, st.st_mode)

    # move payload (everything but info/) into the env
    for rel in files:
        src = os.path.join(tmp, rel)
        dst = os.path.join(target, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.lexists(dst):
            os.remove(dst)
        os.rename(src, dst)

    meta = dict(index)
    meta["files"] = files
    os.makedirs(os.path.join(target, "conda-meta"), exist_ok=True)
    name = "%s-%s-%s.json" % (index["name"], index["version"], index["build"])
    with open(os.path.join(target, "conda-meta", name), "w") as fh:
        json.dump(meta, fh, indent=2, sort_keys=True)

    shutil.rmtree(tmp)
    return index["name"]


def main():
    target, final_prefix, pkgs = sys.argv[1], sys.argv[2], sys.argv[3:]
    os.makedirs(target, exist_ok=True)
    for pkg in pkgs:
        print("installing", install(pkg, target, final_prefix), file=sys.stderr)
    open(os.path.join(target, "conda-meta", "history"), "a").close()


if __name__ == "__main__":
    main()
