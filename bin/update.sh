#!/bin/bash

set -x

NAME=gentoo-devel-updating
PORTAGE=portagesnap
TOOLS=/tools
DATA_DIR=/mnt/disks
BUILDER_DIR=/var/lib/builder

clean_images() {
    toclean=$(docker images -f "dangling=true" -q)
    [ -n "${toclean}" ] && docker rmi ${toclean}
}

clean_images

docker pull gentoo/portage &&
    docker pull gentoo/stage3-amd64 || exit 1

if [ -n "$(docker ps -qaf name=${NAME})" ]; then
    if [ -n "$(docker ps -qf name=${NAME})" ]; then
	docker kill ${NAME} || exit 1
    fi
    docker rm ${NAME} || exit 1
fi
if [ "$(docker ps -af 'name=${PORTAGE}' --format='{{.Image}}')" != "gentoo/portage:latest" ]; then
    if [ -n "$(docker ps -qaf name=${PORTAGE})" ]; then
	docker rm ${PORTAGE} || exit 1
    fi
    clean_images
    time docker create -v /usr/portage \
	 --name ${PORTAGE} gentoo/portage:latest /bin/true \
	|| exit 1
fi

docker images

time docker run --name ${NAME} \
     --log-driver=gcplogs \
     --volumes-from=${PORTAGE} \
     -v ${BUILDER_DIR}/bin-guest:${TOOLS}:ro \
     -v ${DATA_DIR}/ccache:/var/cache/ccache \
     -v ${DATA_DIR}/distfiles:/usr/portage/distfiles \
     -v ${DATA_DIR}/packages:/usr/portage/packages \
     gentoo/stage3-amd64:latest \
     ${TOOLS}/build-devel.sh \
    && docker commit ${NAME} gentoo-devel:latest \
    && docker rm ${NAME}

clean_images
docker ps -a
docker images

sync; sync
sudo shutdown -h now
