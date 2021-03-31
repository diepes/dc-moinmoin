#! /bin/sh

set -e
# Cleanup compiled python form test mount
rm -f moin-config/*.pyc

MOINMOINVERSION=1.9.11

#docker build --pull --build-arg version=${MOINMOINVERSION} -t lukasnellen/moinmoin -t lukasnellen/moinmoin:${MOINMOINVERSION} \
#       -f Dockerfile .
time docker build --pull --build-arg version=${MOINMOINVERSION} -t moinmoin:${MOINMOINVERSION}-debug \
       -f Dockerfile.debug .
#docker build --pull --build-arg version=${MOINMOINVERSION} -t lukasnellen/moinmoin:${MOINMOINVERSION}-slim \
#       -f Dockerfile.slim .
