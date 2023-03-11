#! /bin/bash
set -ex

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

export SED=sed
export EGREP="grep -E"
export FGREP="grep -F"
export GREP="grep"
export MKDIR="mkdir"
export MKDIR_P="mkdir -p"

where=$(which "install" 2>/dev/null || true)

if [ -n "${where}" ]; then
  ln -s -f ${where} ./install
fi

export INSTALL="install"

if [[ ${target_platform} == linux-ppc64le ]]; then
  # there are issues with CDTs and there HOST name ...
  pushd "${BUILD_PREFIX}"
  cp -Rn powerpc64le-conda-linux-gnu/* powerpc64le-conda_cos7-linux-gnu/. || true
  cp -Rn powerpc64le-conda_cos7-linux-gnu/* powerpc64le-conda-linux-gnu/. || true
  popd
fi


export PKG_CONFIG_PATH_FOR_BUILD=$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}:${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH_FOR_BUILD}:$BUILD_PREFIX/$BUILD/sysroot/usr/lib64/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/share/pkgconfig

if [ -n "${XDG_DATA_DIRS}" ]; then
  export XDG_DATA_DIRS=${XDG_DATA_DIRS}:$PREFIX/share:$BUILD_PREFIX/share
else
  export XDG_DATA_DIRS=$PREFIX/share:$BUILD_PREFIX/share
fi

configure_args=(
    --disable-Bsymbolic
    --disable-static
    --enable-pixbuf-loader=yes
    --enable-introspection=yes
)

export RUST_TARGET=$CARGO_BUILD_TARGET
unset CARGO_BUILD_TARGET

./configure --prefix=$PREFIX "${configure_args[@]}" || { cat config.log ; exit 1 ; }
make -j$CPU_COUNT
make install

rm -rf $PREFIX/share/gtk-doc

