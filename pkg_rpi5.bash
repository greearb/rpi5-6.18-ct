#!/bin/bash

ARM_ENV="ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-"

LINUX_FW=$HOME/linux-firmware
LINUX_VER=$(cat include/config/kernel.release)

MORSE_DRIVER=$HOME/morse_driver_ct

RPI_ROOT=$(pwd)/rpi_linux
RPI_BOOT=$(pwd)/rpi_linux/boot
KERNEL=kernel_2712
RPI_TGZ=ct$(make kernelversion)-rpi5.tar.gz
sudo rm -fr $RPI_ROOT
mkdir $RPI_ROOT
mkdir $RPI_BOOT
mkdir $RPI_BOOT/firmware
mkdir $RPI_BOOT/overlays

#set -x
make -j32 $ARM_ENV Image modules dtbs || exit 1
sudo env PATH=$PATH make -j12 $ARM_ENV INSTALL_MOD_PATH=$RPI_ROOT modules_install || exit 1
if [[ -d $MORSE_DRIVER ]]; then
        _PWD=$(pwd)
        cd $MORSE_DRIVER
	make -j32 $ARM_ENV MORSE_TRACE_PATH=$MORSE_DRIVER KERNEL_SRC=$_PWD CONFIG_WLAN_VENDOR_MORSE=m CONFIG_MORSE_USB=y CONFIG_MORSE_COUNTRY="US" CONFIG_MORSE_VENDOR_COMMAND=y CONFIG_MORSE_MONITOR=y CONFIG_MORSE_SDIO=y CONFIG_MORSE_SPI=y CONFIG_MORSE_DEBUG_MASK=2 MORSE_TRACE_PATH=$MORSE_DRIVER || exit 1
        sudo cp morse.ko dot11ah/dot11ah.ko $RPI_ROOT/lib/modules/$LINUX_VER/kernel/net || exit 1
        sudo cp -ar lib/firmware/morse $RPI_ROOT/lib/firmware/ || exit 1
        cd $_PWD
fi

sudo cp arch/arm64/boot/Image $RPI_BOOT/firmware/$KERNEL.img || exit 1
sudo cp arch/arm64/boot/dts/broadcom/*.dtb $RPI_BOOT/ || exit 1
sudo cp arch/arm64/boot/dts/overlays/*.dtb* $RPI_BOOT/overlays/ || exit 1
sudo cp arch/arm64/boot/dts/overlays/README $RPI_BOOT/overlays/ || exit 1
sudo cp .config $RPI_BOOT/config-$LINUX_VER || exit 1

if [[ -d $LINUX_FW ]]; then
	echo "Packaging firmware from $LINUX_FW"
	sudo mkdir -p $RPI_ROOT/lib/firmware/mediatek || exit 1
	sudo cp -ar $LINUX_FW/mediatek/* $RPI_ROOT/lib/firmware/mediatek/ || exit 1
	sudo cp -ar $LINUX_FW/intel/iwlwifi/* $RPI_ROOT/lib/firmware/ || exit 1
fi

cd $RPI_ROOT/
tar -czf ../$RPI_TGZ *

pwd
echo "Kernel package: $RPI_TGZ"
echo "Install by running \`tar --no-same-owner -mhxzf $RPI_TGZ\` in /"
cd -

# To install, something like:
# tar --no-same-owner -mhxzf ct6.18.40-rpi5.tar.gz
