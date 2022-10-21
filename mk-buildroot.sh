#!/bin/bash

set -e

cd ./buildroot/
source ../device/rockchip/.BoardConfig.mk
make firefly_rk3588_defconfig
make 
cp ./output/images/rootfs.ext2 ../out/
