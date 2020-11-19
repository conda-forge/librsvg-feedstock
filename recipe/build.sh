#! /bin/bash
set -ex

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

if [[ $target_platform == osx-* ]] ; then
  # Workaround for https://gitlab.gnome.org/GNOME/librsvg/-/issues/545 ; should be removable soon.
  export LDFLAGS="$LDFLAGS -lobjc"
fi


if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    unset CARGO_BUILD_TARGET
    mkdir -p native-build
    pushd native-build

    export CC=$CC_FOR_BUILD
    export AR=($CC_FOR_BUILD -print-prog-name=ar)
    export NM=($CC_FOR_BUILD -print-prog-name=nm)
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS
    export host_alias=$build_alias

    ../configure --prefix=$BUILD_PREFIX  --disable-Bsymbolic

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$PREFIX/libexec/gi-cross-launcher-save.sh
    make -j${CPU_COUNT}
    make install
    rm -rf $PREFIX/bin/g-ir-scanner $PREFIX/bin/g-ir-compiler
    ln -s $BUILD_PREFIX/bin/g-ir-scanner $PREFIX/bin/g-ir-scanner
    ln -s $BUILD_PREFIX/bin/g-ir-compiler $PREFIX/bin/g-ir-compiler
    rsync -ahvpiI $BUILD_PREFIX/lib/gobject-introspection/ $PREFIX/lib/gobject-introspection/
    popd
  )
  export GI_CROSS_LAUNCHER=$PREFIX/libexec/gi-cross-launcher-load.sh
fi

export RUST_TARGET=$CARGO_BUILD_TARGET
unset CARGO_BUILD_TARGET

./configure --prefix=$PREFIX --disable-Bsymbolic || { cat config.log ; exit 1 ; }
make -j$CPU_COUNT
make install

rm -rf $PREFIX/share/gtk-doc
