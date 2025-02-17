#!/bin/bash -e
#
# Adapted from NiLuJe's build script:
# http://www.mobileread.com/forums/showthread.php?t=88004
# (live copy: https://svn.ak-team.com/svn/Configs/trunk/Kindle/Misc/x-compile.sh)
#
# =================== original header ====================
#
# Kindle cross toolchain & lib/bin/util build script
#
# $Id$
#
# kate: syntax bash;
#

## Using CrossTool-NG (http://crosstool-ng.org/)

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

Build_CT-NG() {
	echo "[*] Building CrossTool-NG . . ."
	tc_target="$1"
	PARALLEL_JOBS=$(($(getconf _NPROCESSORS_ONLN 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 0) + 1))
	echo "[-] ct-ng git repo: ${ct_ng_git_repo}"
	echo "[-] ct-ng commit hash: ${ct_ng_commit}"
	echo "[-] compiling with ${PARALLEL_JOBS} parallel jobs"
	echo "[-] toolchain target: ${tc_target}"

	git submodule update --init --recursive
	pushd CT-NG
		git clean -fxdq
		./bootstrap
		[ ! -d "CT_NG_BUILD" ] && mkdir -p "CT_NG_BUILD"
		./configure --prefix="$(pwd)/CT_NG_BUILD"
		make -j${PARALLEL_JOBS}
		make install
		#export PATH="$(pwd)/CT_NG_BUILD/bin:${PATH}"
		CT_NG_PATH="$(pwd)/CT_NG_BUILD/bin/ct-ng"
	popd
	# extract platform name from target tuple
	tmp_str="${tc_target#*-}"
	TC_BUILD_DIR="build/${tmp_str%%-*}"
	[ ! -d "${TC_BUILD_DIR}" ] && mkdir -p "${TC_BUILD_DIR}"
	pushd "${TC_BUILD_DIR}"
		$CT_NG_PATH distclean

		unset CFLAGS CXXFLAGS LDFLAGS
		$CT_NG_PATH "${tc_target}"
		$CT_NG_PATH oldconfig
		$CT_NG_PATH upgradeconfig
		$CT_NG_PATH updatetools
		nice $CT_NG_PATH build.$PARALLEL_JOBS
		echo ""
		echo "[INFO ]  ================================================================="
		echo "[INFO ]  Build done. Please add $HOME/x-tools/${tc_target}/bin to your PATH."
		echo "[INFO ]  ================================================================="
	popd

	echo "[INFO ]  ================================================================="
	echo "[INFO ]  The x-compile.sh script can do that (and more) for you:"
	echo "[INFO ]  * If you need a persistent custom sysroot (e.g., if you intend to build a full dependency chain)"
	echo "[INFO ]    > source ${PWD}/refs/x-compile.sh ${TC_BUILD_DIR} env"
	echo "[INFO ]  * If you just need a compiler:"
	echo "[INFO ]    > source ${PWD}/refs/x-compile.sh ${TC_BUILD_DIR} env bare"
}

HELP_MSG="
usage: $0 PLATFORM

Supported platforms:

	kindle
	kindle5
	kindlepw2
	kindlehf
	kobo
	kobov4
	kobov5
	nickel
	remarkable
	cervantes
	pocketbook
	bookeen
"

if [ $# -lt 1 ]; then
	echo "Missing argument"
	echo "${HELP_MSG}"
	exit 1
fi

case $1 in
	-h)
		echo "${HELP_MSG}"
		exit 0
		;;
	kobov5)
		Build_CT-NG "arm-${1}-linux-gnueabihf"
		;;
	kobov4)
		Build_CT-NG "arm-${1}-linux-gnueabihf"
		;;
	kobo)
		Build_CT-NG "arm-${1}-linux-gnueabihf"
		;;
	nickel)
		Build_CT-NG "arm-${1}-linux-gnueabihf"
		;;
	kindlehf)
		Build_CT-NG "arm-${1}-linux-gnueabihf"
		;;
	kindlepw2)
		Build_CT-NG "arm-${1}-linux-gnueabi"
		;;
	kindle5)
		Build_CT-NG "arm-${1}-linux-gnueabi"
		;;
	kindle)
		# NOTE: Prevent libstdc++ from pulling in utimensat@GLIBC_2.6
		export glibcxx_cv_utimensat=no

		Build_CT-NG "arm-${1}-linux-gnueabi"
		unset glibcxx_cv_utimensat
		;;
	remarkable)
		Build_CT-NG "arm-${1}-linux-gnueabihf"
		;;
	cervantes)
		Build_CT-NG "arm-${1}-linux-gnueabi"
		;;
	pocketbook)
		# NOTE: Prevent libstdc++ from pulling in utimensat@GLIBC_2.6
		export glibcxx_cv_utimensat=no

		Build_CT-NG "arm-${1}-linux-gnueabi"
		# Then, pull InkView from the (old) official SDK...
		# NOTE: See also https://github.com/pocketbook/SDK_6.3.0/tree/5.19/SDK-iMX6/usr/arm-obreey-linux-gnueabi/sysroot/usr/local for newer FWs...
		chmod a+w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/lib/libinkview.481.5.17.so \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libinkview.so"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libinkview.so"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/lib/libhwconfig.so \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libhwconfig.so"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libhwconfig.so"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/FRSCSDK/arm-none-linux-gnueabi/sysroot/usr/lib/libbookstate.so \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libbookstate.so"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libbookstate.so"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib"
		chmod a+w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inkview.h \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		# Don't pull 3rd-party includes...
		sed -e '/^#include <zlib.h>/i \/*' -i "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		sed -e '/^#include FT_OUTLINE_H/a *\/' -i "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		# NOTE: This also comments <pthread.h>, which the header itself doesn't need anyway...
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inkplatform.h \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkplatform.h"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkplatform.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inklog.h \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inklog.h"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inklog.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inkinternal.h \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkinternal.h"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkinternal.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/hwconfig.h \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/hwconfig.h"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/hwconfig.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/FRSCSDK/arm-none-linux-gnueabi/sysroot/usr/include/bookstate.h \
			-O "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/bookstate.h"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/bookstate.h"
		chmod a-w "${HOME}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include"

		unset glibcxx_cv_utimensat
		;;
	bookeen)
		Build_CT-NG "arm-${1}-linux-gnueabi"
		;;
	*)
		echo "[!] $1 not supported!"
		echo "${HELP_MSG}"
		exit 1
		;;
esac
