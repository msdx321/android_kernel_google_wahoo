#!/bin/bash


ROOT_DIR=$(pwd)
OUT_DIR=$ROOT_DIR/out
BUILDING_DIR=$OUT_DIR/kernel_obj
AK2_DIR=$ROOT_DIR/misc/ak2
TEMP_DIR=$OUT_DIR/temp

JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
DATE=`date +%m-%d-%H:%M`

TESTBUILD=$1


CROSS_COMPILER=$ROOT_DIR/toolchains/linaro-gcc/bin/aarch64-linux-gnu-
CC_COMPILER=/home/msdx321/workspace/android/toolchains/dtc/out/5.0/bin/clang

export ARCH=arm64

export PATH=$PATH:$ROOT_DIR/misc/bin

export SUBVER="R6"

FUNC_PRINT()
{
	echo ""
	echo "=============================================="
	echo $1
	echo "=============================================="
	echo ""
}

FUNC_COMPILE_KERNEL()
{
	FUNC_PRINT "Start Compiling Kernel"

    if [ "$TESTBUILD" = "test" ]; then
        export LOCALVERSION="-mKernel-Nightly"
    else
        export LOCALVERSION="-mKernel-$SUBVER"
    fi

	make -C $ROOT_DIR O=$BUILDING_DIR mrproper -j$JOB_NUMBER
	make -C $ROOT_DIR O=$BUILDING_DIR mKernel_walleye_defconfig
	make -C $ROOT_DIR O=$BUILDING_DIR -j$JOB_NUMBER CROSS_COMPILE=$CROSS_COMPILER CC="ccache $CC_COMPILER" HOSTCC=clang

    if [ ! -f "out/kernel_obj/arch/arm64/boot/Image.lz4-dtb" ]; then
        FUNC_PRINT "ERROR"
        exit 1
    fi

	FUNC_PRINT "Finish Compiling Kernel"
}

FUNC_PACK()
{
	FUNC_PRINT "Start Packing"

	rm -rf $TEMP_DIR
	mkdir -p $TEMP_DIR
	cp -r $AK2_DIR/* $TEMP_DIR
	cp $BUILDING_DIR/arch/arm64/boot/Image.lz4-dtb $TEMP_DIR/zImage
	cp $BUILDING_DIR/arch/arm64/boot/dtbo.img $TEMP_DIR/dtbo.img
	cd $TEMP_DIR
	zip -r9 mKernel.zip ./*

	if [ "$TESTBUILD" = "test" ]; then
		mv mKernel.zip $OUT_DIR/mKernel-$DATE.zip
	else
		mv mKernel.zip $OUT_DIR/mKernel-$SUBVER.zip
	fi

	cd $ROOT_DIR

	FUNC_PRINT "Finish Packing"
}

START_TIME=`date +%s`
FUNC_COMPILE_KERNEL
FUNC_PACK
END_TIME=`date +%s`

let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo "Total compile time is $ELAPSED_TIME seconds"
