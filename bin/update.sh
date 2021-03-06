#!/bin/bash

set -x

: ${ORG:=}
: ${DOCKER:=docker}
NAME="gentoo-devel"
PORTAGE=portagesnap
TOOLS=/tools
DATA_DIR=/mnt/disks
BUILDER_DIR=/var/lib/builder

clean_images() {
    toclean=$(docker images -f "dangling=true" -q)
    [ -n "${toclean}" ] && docker rmi ${toclean}
}

if [ -n "${ORG}" ]; then
    NAME="${ORG}/${NAME}"
fi

UPDATING="gentoo-devel-updating"

clean_images
${DOCKER} pull gentoo/portage &&
    ${DOCKER} pull gentoo/stage3-amd64 || exit 1
clean_images

if [ -n "$(${DOCKER} ps -qaf name=${UPDATING})" ]; then
    if [ -n "$(${DOCKER} ps -qf name=${UPDATING})" ]; then
	${DOCKER} kill ${UPDATING} || exit 1
    fi
    ${DOCKER} rm -v ${UPDATING} || exit 1
fi
if [ "$(${DOCKER} ps -af "name=${PORTAGE}" --format='{{.Image}}')" != "gentoo/portage:latest" ]; then
    if [ -n "$(${DOCKER} ps -qaf name=${PORTAGE})" ]; then
	${DOCKER} rm -v ${PORTAGE} || exit 1
    fi
    time ${DOCKER} create -v /usr/portage \
	 --name ${PORTAGE} gentoo/portage:latest /bin/true \
	|| exit 1
fi

${DOCKER} images

time ${DOCKER} run --name ${UPDATING} \
     --log-driver=gcplogs \
     -v /dev/shm --tmpfs /dev/shm:rw,suid,dev,exec,size=10g \
     --volumes-from=${PORTAGE} \
     -v ${BUILDER_DIR}/bin-guest:${TOOLS}:ro \
     -v ${DATA_DIR}/ccache:/var/cache/ccache \
     -v ${DATA_DIR}/distfiles:/usr/portage/distfiles \
     -v ${DATA_DIR}/packages:/usr/portage/packages \
     gentoo/stage3-amd64:latest \
     ${TOOLS}/build-devel.sh \
    && ${DOCKER} commit ${UPDATING} ${NAME}:latest \
    && ${DOCKER} rm -v ${UPDATING}

built=$?
if [ $built = 0 -a -n "${ORG}" ]; then
    ${DOCKER} push ${NAME}:latest &&
	${DOCKER} rmi ${NAME}:latest
fi

clean_images
${DOCKER} ps -a
${DOCKER} images

sync; sync
sudo shutdown -h now
