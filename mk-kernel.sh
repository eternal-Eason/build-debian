#!/bin/bash -e

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
EXTLINUXPATH=${LOCALPATH}/build/extlinux
BOARD=$1

version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

finish() {
	echo -e "\e[31m MAKE KERNEL IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR


model_list=(
	"rk3588-rock-5b"
	"rk3588-rock-5b menuconfig"
	"rk3588-rock-5b savedefconfig"
	"rk3588-rock-5b distclean"
)

function help()
{
	echo "Usage: ./build/mk-kernel.sh rk3588-rock-5b"
	echo "e.g."
	for i in "${model_list[@]}"; do
		echo "  ./build/mk-kernel.sh $(echo $i)"
	done
}

help

[ ! -d ${OUT} ] && mkdir ${OUT}
[ ! -d ${OUT}/kernel ] && mkdir ${OUT}/kernel

source $LOCALPATH/build/board_configs.sh $BOARD



echo -e "\e[36m Building kernel for ${BOARD} board! \e[0m"

KERNEL_VERSION=$(cd ${LOCALPATH}/kernel && make kernelversion)
echo $KERNEL_VERSION

if version_gt "${KERNEL_VERSION}" "4.5"; then
	if [ "${DTB_MAINLINE}" ]; then
		DTB=${DTB_MAINLINE}
	fi

	if [ "${DEFCONFIG_MAINLINE}" ]; then
		DEFCONFIG=${DEFCONFIG_MAINLINE}
	fi
fi

cd ${LOCALPATH}/kernel


[ ! -e .config ] && echo -e "\e[36m Using ${DEFCONFIG} \e[0m" && make ${DEFCONFIG}

if [ "$2" == "menuconfig" ]; then
	make menuconfig
	exit
elif [ "$2" == "savedefconfig" ]; then
	make savedefconfig
	exit
elif [ "$2" == "distclean" ]; then
	make distclean
	exit
else
	make -j$(nproc)
fi



cd ${LOCALPATH}

if [ "${ARCH}" == "arm" ]; then
	cp ${LOCALPATH}/kernel/arch/arm/boot/zImage ${OUT}/kernel/
	cp ${LOCALPATH}/kernel/arch/arm/boot/dts/${DTB} ${OUT}/kernel/
else
	cp ${LOCALPATH}/kernel/arch/arm64/boot/Image ${OUT}/kernel/
	cp ${LOCALPATH}/kernel/arch/arm64/boot/dts/rockchip/${DTB} ${OUT}/kernel/
fi

# Change extlinux.conf according board
sed -e "s,fdt .*,fdt /$DTB,g" \
	-i ${EXTLINUXPATH}/${CHIP}.conf

./build/mk-image.sh -c ${CHIP} -t boot -b ${BOARD}

echo -e "\e[36m Kernel build success! \e[0m"
