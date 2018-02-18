#!/bin/bash

set -x

BUILDER_DIR=/var/lib/builder

restart=$(findmnt /var/lib/docker)

cp ${BUILDER_DIR}/fstab /etc/fstab
mkdir -p $(awk '{print $2}' /etc/fstab)
mount -a

if [ ! -e /etc/default/docker ]; then
    ln -sf ${BUILDER_DIR}/docker.conf /etc/default/docker
    restart=1
fi

mkdir -p /etc/google/auth/
ln -sf ${BUILDER_DIR}/cred.json /etc/google/auth/application_default_credentials.json

ln -sf /var/lib/builder/build-devel.service /etc/systemd/system

if [ -n "${restart}" ]; then
    systemctl restart docker
    umount /var/lib/docker || true
fi
