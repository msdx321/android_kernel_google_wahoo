#!/bin/bash

export ARCH=arm64
export SUBVER="R1"
export LOCALVERSION="-mKernel-$SUBVER"

ROOT_DIR=$(pwd)
OUT_DIR=$ROOT_DIR/out
BUILDING_DIR=$OUT_DIR/kernel_obj

JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
DATE=`date +%m-%d-%H:%M`

CROSS_COMPILER=/home/msdx321/workspace/android/toolchains/linaro-4.9.4/bin/aarch64-linux-gnu-
CC_COMPILER=/home/msdx321/workspace/android/toolchains/clang-3859424/bin/clang

AK2_DIR=$ROOT_DIR/ak2
TEMP_DIR=$OUT_DIR/temp

TESTBUILD=$1

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
	make -C $ROOT_DIR O=$BUILDING_DIR mrproper -j$JOB_NUMBER
	make -C $ROOT_DIR O=$BUILDING_DIR mKernel_defconfig
	make -C $ROOT_DIR O=$BUILDING_DIR -j$JOB_NUMBER ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILER CC="ccache $CC_COMPILER" HOSTCC=clang
	FUNC_PRINT "Finish Compiling Kernel"
}

FUNC_PACK()
{
	FUNC_PRINT "Start Packing"
	rm -rf $TEMP_DIR
	mkdir -p $TEMP_DIR
	cp -r $AK2_DIR/* $TEMP_DIR
	cp $BUILDING_DIR/arch/arm64/boot/Image.lz4-dtb $TEMP_DIR/zImage
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
