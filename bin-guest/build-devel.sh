#!/bin/bash

set -x

export LANG=en_US.utf8

cat >/etc/portage/bashrc <<EOF
if [[ \${FEATURES} == *ccache* && \${EBUILD_PHASE_FUNC} == src_* ]]; then
	export CCACHE_DIR=/var/cache/ccache/\${CATEGORY}/\${PN}:\${SLOT}
	mkdir -p "\${CCACHE_DIR}" || die
fi
EOF

cat >/etc/locale.gen <<EOF
en_US UTF-8
en_US.UTF-8 UTF-8
EOF

export MAKEOPTS="-j$(nproc) -l$(nproc)"
export PORTAGE_TMPDIR=/dev/shm
EMERGE_OPTS="-j --load-average $(nproc) -bk --binpkg-respect-use=y --buildpkg-exclude virtual/*"
echo 'ACCEPT_KEYWORDS="~amd64 amd64"' >> /etc/portage/make.conf &&
	echo 'CCACHE_DIR="/var/cache/ccache"' >> /etc/portage/make.conf &&
	echo 'FEATURES="${FEATURES} buildpkg binpkg-multi-instance"' >> /etc/portage/make.conf &&
	echo 'FEATURES="${FEATURES} ccache parallel-install -news -sandbox -usersandbox"' >> /etc/portage/make.conf &&
	echo 'BINPKG_COMPRESS=xz' >> /etc/portage/make.conf &&
	eselect news read new > /dev/null &&
	emerge ${EMERGE_OPTS} flaggie ccache &&
	flaggie sys-apps/portage +gentoo-dev &&
	emerge --info -v > /emerge-info.txt &&
	emerge -uDNv --with-bdeps=y ${EMERGE_OPTS} world &&
	emerge ${EMERGE_OPTS} @preserved-rebuild &&
	eselect news read new > /dev/null &&
	emerge --depclean
