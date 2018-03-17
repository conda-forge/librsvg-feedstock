#! /bin/bash

set -e

# 2018 Mar 17: Work around SSL problem; see https://github.com/conda-forge/mosfit-feedstock/issues/23
unset REQUESTS_CA_BUNDLE
unset SSL_CERT_FILE

configure_args=(
    --prefix=$PREFIX
    --disable-Bsymbolic
)

rm -f $PREFIX/lib/*.la # deps have busted files
./configure "${configure_args[@]}" || { cat config.log ; exit 1 ; }
make -j$CPU_COUNT
make install

cd $PREFIX
find . '(' -name '*.la' -o -name '*.a' ')' -delete
rm -rf share/gtk-doc
