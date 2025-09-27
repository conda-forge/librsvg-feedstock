#! /bin/bash

set -exuo pipefail

# $BUILD_PREFIX needed here so gi-docgen can find .gir files:
export XDG_DATA_DIRS="${XDG_DATA_DIRS:+$XDG_DATA_DIRS:}$PREFIX/share:$BUILD_PREFIX/share"

# https://github.com/rust-lang/cargo/issues/10583#issuecomment-1129997984
export CARGO_NET_GIT_FETCH_WITH_CLI=true

meson_config_args=(
    -Dpixbuf=enabled
    -Dpixbuf-loader=enabled
)

##if [[ $target_platform == osx-* ]] ; then
##  # Workaround for https://gitlab.gnome.org/GNOME/librsvg/-/issues/545 ; should be removable soon.
##  export LDFLAGS="$LDFLAGS -lobjc"
##fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    unset CARGO_BUILD_TARGET
    mkdir -p native-build

    export CC=$CC_FOR_BUILD
    export AR="$($CC_FOR_BUILD -print-prog-name=ar)"
    export NM="$($CC_FOR_BUILD -print-prog-name=nm)"
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS
    export host_alias=$build_alias
    export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig

    meson setup native-build \
      "${meson_config_args[@]}" \
      --prefix="$BUILD_PREFIX" \
      -Dintrospection=enabled \
      -Dlocalstatedir="$BUILD_PREFIX/var" \
      || { cat native-build/meson-logs/meson-log.txt ; exit 1 ; }

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-save.sh
    ninja -C native-build -j${CPU_COUNT}
    ninja -C native-build install

    # Store generated introspection information
    mkdir -p introspection/lib introspection/share
    cp -ap $BUILD_PREFIX/lib/girepository-1.0 introspection/lib
    cp -ap $BUILD_PREFIX/share/gir-1.0 introspection/share
  )
  export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-load.sh
  export MESON_ARGS="${MESON_ARGS} -Dintrospection=disabled"
else
  export MESON_ARGS="${MESON_ARGS} -Dintrospection=enabled"
fi

export PKG_CONFIG_PATH_FOR_BUILD=$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig

export RUST_TARGET=$CARGO_BUILD_TARGET
unset CARGO_BUILD_TARGET

meson setup builddir \
  ${MESON_ARGS} \
  "${meson_config_args[@]}" \
  --prefix="$PREFIX" \
  -Dlocalstatedir="$PREFIX/var" \
  || { cat builddir/meson-logs/meson-log.txt ; exit 1 ; }

ninja -C builddir -j$CPU_COUNT -v
ninja -C builddir install

rm -rf $PREFIX/share/doc
