#!/bin/bash

set -x

LANG=en_US.utf8

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
EMERGE_OPTS="-j --load-average $(nproc) -bk --binpkg-respect-use=y"
echo 'ACCEPT_KEYWORDS="~amd64 amd64"' >> /etc/portage/make.conf &&
	echo 'CCACHE_DIR="/var/cache/ccache"' >> /etc/portage/make.conf &&
	echo 'FEATURES="binpkg-multi-instance ccache parallel-install -sandbox -usersandbox"' >> /etc/portage/make.conf &&
	eselect news read new > /dev/null &&
	emerge ${EMERGE_OPTS} flaggie ccache &&
	flaggie +bindist &&
	flaggie sys-apps/portage +gentoo-dev &&
	emerge --info -v > /emerge-info.txt &&
	emerge -uDNv --with-bdeps=y ${EMERGE_OPTS} world &&
	emerge ${EMERGE_OPTS} @preserved-rebuild &&
	eselect news read new > /dev/null &&
	emerge --depclean
