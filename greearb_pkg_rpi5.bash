#!/bin/bash

LINUX_FW=/home/greearb/linux-firmware
LINUX_VER=$(make kernelversion)

MORSE_DRIVER=/home/greearb/git/morse_driver_ct

RPI_ROOT=/home/greearb/tmp/rpi_linux
RPI_BOOT=/home/greearb/tmp/rpi_linux/boot
KERNEL=kernel_2712
RPI_TGZ=ct$LINUX_VER-rpi5.tar.gz
sudo rm -fr $RPI_ROOT
mkdir $RPI_ROOT
mkdir $RPI_BOOT
mkdir $RPI_BOOT/firmware
mkdir $RPI_BOOT/overlays

#set -x
make -j8 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs || exit 1
sudo env PATH=$PATH make -j12 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$RPI_ROOT modules_install || exit 1
if [[ -d $MORSE_DRIVER ]]; then
	make -j32 $ARM_ENV -C $(pwd) M=$MORSE_DRIVER MORSE_TRACE_PATH=$MORSE_DRIVER KERNEL_SRC=$(pwd) CONFIG_WLAN_VENDOR_MORSE=m CONFIG_MORSE_USB=y CONFIG_MORSE_COUNTRY="US" CONFIG_MORSE_VENDOR_COMMAND=y CONFIG_MORSE_MONITOR=y CONFIG_MORSE_SDIO=y CONFIG_MORSE_SPI=y CONFIG_MORSE_DEBUG_MASK=2 MORSE_TRACE_PATH=$MORSE_DRIVER modules || exit 1
	sudo env PATH=$PATH make $ARM_ENV -C $(pwd) M=$MORSE_DRIVER INSTALL_MOD_PATH=$RPI_ROOT modules_install || exit 1
fi
sudo cp arch/arm64/boot/Image $RPI_BOOT/firmware/$KERNEL.img || exit 1
sudo cp arch/arm64/boot/dts/broadcom/*.dtb $RPI_BOOT/ || exit 1
sudo cp arch/arm64/boot/dts/overlays/*.dtb* $RPI_BOOT/overlays/ || exit 1
sudo cp arch/arm64/boot/dts/overlays/README $RPI_BOOT/overlays/ || exit 1
sudo cp .config $RPI_BOOT/config-$LINUX_VER-v8-16k-ct+ || exit 1

echo "Packaging firmware from $LINUX_FW"
sudo mkdir -p $RPI_ROOT/lib/firmware/mediatek || exit 1
sudo cp -ar $LINUX_FW/mediatek/* $RPI_ROOT/lib/firmware/mediatek/ || exit 1
sudo cp -ar $LINUX_FW/intel/iwlwifi/* $RPI_ROOT/lib/firmware/ || exit 1

cd $RPI_ROOT/
tar -czf ../$RPI_TGZ *

pwd
echo "Kernel package: $RPI_TGZ"
cd -

# To install, something like:
# tar --no-same-owner -mhxzf ct6.18.40-rpi5.tar.gz
