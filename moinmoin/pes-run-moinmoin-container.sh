#! /bin/sh

set -e

MOINMOINVERSION=1.9.11
# 
# docker run -d --rm -p 8080:8080 \
podman run -d --rm -p 8080:8080 \
       	-v /var/lib/moinmoin/vigor/data:/opt/share/moin/data \
	-v /var/lib/moinmoin/underlay:/opt/share/moin/underlay \
	-v ${PWD}/moinmoin/moin-config:/config/moin \
         moinmoin:${MOINMOINVERSION}-debug


# docker ps
podman ps

