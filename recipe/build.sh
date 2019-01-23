#! /bin/bash

set -ex

configure_args=(
    --prefix=$PREFIX
    --disable-Bsymbolic
)

if [[ $(uname) == Darwin ]] ; then
    # OK, I have no idea what's happening here, but the macOS build breaks on
    # Travis if I don't do this?? But not on my local machine?? I discovered
    # this workaround while flailing around with errors that resembled the
    # pkg-config problems worked around in `tectonic-feedstock`. The errors
    # look like the same problem we get there with Cargo setting
    # $DYLD_LIBRARY_PATH, but seeing as this wrapper script *does nothing* I
    # just have no idea now. But it will be worth checking whether this is
    # still needed after Rust 1.33 comes out, since that should start setting
    # $DYLD_FALLBACK_LIBRARY_PATH instead,
    rustc=$(which rustc)
    mv $rustc $rustc.bin
    cat <<'EOF' >$rustc
#!/usr/bin/env bash
exec rustc.bin "$@"
EOF
    chmod +x $rustc
fi

rm -f $PREFIX/lib/*.la # deps have busted files
./configure "${configure_args[@]}" || { cat config.log ; exit 1 ; }
make -j$CPU_COUNT
make install

cd $PREFIX
find . '(' -name '*.la' -o -name '*.a' ')' -delete
rm -rf share/gtk-doc
