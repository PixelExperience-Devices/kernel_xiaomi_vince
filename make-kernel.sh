#! /bin/bash

# Copyright (C) 2021-2022 rk134
# Thanks to eun0115, starlight5234 and ghostmaster69-dev
export DEVICE="VINCE"
export CONFIG="platinum_defconfig"
export TC_PATH="$HOME/toolchains"
PATH="${PWD}/clang/bin:$PATH"
PATH="${PWD}/los-4.9-32/bin:$PATH"
PATH="${PWD}/los-4.9-64/bin:$PATH"
export ZIP_DIR="$(pwd)/AnyKernel3"
export KERNEL_DIR=$(pwd)
export ATOM_COMPILE="yes"
export KBUILD_BUILD_USER="rk134"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

# FUNCTIONS

# Ask Telegram Channel/Chat ID -- thanks to @Ghostmaster69-dev
if [[ -z ${CHANNEL_ID} ]]; then
    echo -n "Sup dude! Please give me your telegram channel ID: "
    read -r tg_channel_id
    CHANNEL_ID="${tg_channel_id}"
fi

# Ask Telegram Bot API Token -- thanks to @Ghostmaster69-dev
if [[ -z ${TELEGRAM_TOKEN} ]]; then
    echo -n "Please give me your telegram bot token: "
    read -r tg_token
    TELEGRAM_TOKEN="${tg_token}"
fi

# Ask type of build for building
if [[ -z ${TYPE} ]]; then
	echo -n "Please enter the type of build: "
	read -r TYPE
	TYPE="${TYPE}"
fi

# Upload buildlog to group
tg_erlog()
{
	ERLOG=$HOME/build/build${BUILD}.txt
	curl -F document=@"$ERLOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build ran into errors after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds, plox check logs"
}

# Upload zip to channel
tg_pushzip() 
{
	FZIP=$ZIP_DIR/$ZIP
	curl -F document=@"$FZIP"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build Finished after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
}

# Upload download link to channel
tg_pushlink()
{
        export zip_directory="$(cd $(pwd)/AnyKernel3/ && ls *.zip)"
        rclone copy $(pwd)/AnyKernel3/*.zip ccache:vince -P
        curl -s https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$CHANNEL_ID -d text="Download link https://retarded-sprout.axsp.workers.dev/vince/$zip_directory"
}

# Send Updates
function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id="${CHANNEL_ID}" \
		-d "disable_web_page_preview=true"
}

# Clone the toolchains and export required information
function clone_tc() {
[ -d ${TC_PATH} ] || mkdir ${TC_PATH}

if [ "$AZURE_COMPILE" == "no" ]; then
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git ${TC_PATH}/clang
	export PATH="${TC_PATH}/clang/bin:$PATH"
	export STRIP="${TC_PATH}/clang/aarch64-linux-gnu/bin/strip"
	export COMPILER="Clang 14.0.0"
else
    git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang clang --depth=1
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64 --depth=1
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32 --depth=1
    export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
fi
}
# Send Updates
function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id="${CHANNEL_ID}" \
		-d "disable_web_page_preview=true"
}

# Send a sticker
function start_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="CAACAgQAAxkBAAEDIYdhctPrAm1Ydl3sFori9vNNnjAoigAC9AkAAl79YVHW7zfYKT9-XyEE" \
        -d chat_id=$CHANNEL_ID
}

function error_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="$STICKER" \
        -d chat_id=$CHANNEL_ID
}

# Compile this gay-ass kernel
function compile() {
DATE=`date`
BUILD_START=$(date +"%s")
make O=out ARCH=arm64 platinum_defconfig
make -j$(nproc --all) O=out \
                ARCH=arm64 \
			    CC="ccache clang" \
			    CROSS_COMPILE=aarch64-linux-gnu- \
			    CROSS_COMPILE_ARM32=arm-linux-gnueabi- |& tee -a $HOME/build/build${BUILD}.txt

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
}

# Zip this gay-ass kernel
function make_flashable() {
    
cd $ZIP_DIR
dir
rm -rf zIm*
rm -rf Platinum*
cp $KERN_IMG $ZIP_DIR/zImage
if [ "$TYPE" == "stable" ]; then
    zip -r9 Platinum-Kernel-v1-[STABLE].zip * -x .git README.md *placeholder
elif [ "$TYPE" == "beta" ]; then
    zip -r9 Platinum-Kernel-v1-[BETA].zip * -x .git README.md *placeholder
else
    zip -r9 Platinum-Kernel-v1-[TEST].zip * -x .git README.md *placeholder
fi
ZIP=$(echo *.zip)
tg_pushzip

}

# Credits: @madeofgreat
BTXT="$HOME/build/buildno.txt" #BTXT is Build number TeXT
if ! [ -a "$BTXT" ]; then
	mkdir $HOME/build
	touch $HOME/build/buildno.txt
	echo $RANDOM > $BTXT
fi

BUILD=$(cat $BTXT)
BUILD=$(($BUILD + 1))
echo ${BUILD} > $BTXT

# Sticker selection
stick=$(($RANDOM % 5))

if [ "$stick" == "0" ]; then
	STICKER="CAACAgIAAxkBAAEDIWhhcssHSMR1HTAHtKOby21tVafvWgAC_gADVp29CtoEYTAu-df_IQQ"
elif [ "$stick" == "1" ];then
	STICKER="CAACAgIAAxkBAAEDIXlhcsvK31evc58huNXRZnSWf62R2AAC_w4AAhSUAAFL2_NFL9rIYIAhBA"
elif [ "$stick" == "2" ];then
	STICKER="CAACAgUAAxkBAAEDIXthcsvYV4zwNP0ousx1ULwkKGRdygACIAADYOojP1RURqxGbEhrIQQ"
elif [ "$stick" == "3" ];then
	STICKER="CAACAgUAAxkBAAEDIX1hcsvr8e6DUr1J4KmHCtI98gx1xwACNgADP9jqMxV1oXRlrlnXIQQ"
elif [ "$stick" == "4" ];then
	STICKER="CAACAgEAAxkBAAEDIYFhcswQNqw8ZPubg7zGQkNhaYGTBAACKwIAAvx0QESn-U6NZyYYfSEE"
fi

#-----------------------------------------------------------------------------------------------------------#
clone_tc
COMMIT=$(git log --pretty=format:'"%h : %s"' -1)
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
KERNEL_DIR=$(pwd)
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
CONFIG_PATH=$KERNEL_DIR/arch/arm64/configs/$CONFIG
VENDOR_MODULEDIR="$ZIP_DIR/modules/vendor/lib/modules"
export KERN_VER=$(echo "$(make kernelversion --no-print-directory)")
make mrproper && rm -rf out
start_sticker
tg_sendinfo "$(echo -e "======= <b>$DEVICE</b> =======\n
Build-Host   :- <code>$KBUILD_BUILD_HOST</code>
Build-User   :- <code>$KBUILD_BUILD_USER</code>\n 
Version      :- <u><code>$KERN_VER</code></u>
Compiler     :- <code>$KBUILD_COMPILER_STRING</code>\n
on Branch    :- <code>$BRANCH</code>
Commit       :- <code>$COMMIT</code>\n
Type         :- <code>$TYPE</code>\n")"

compile
if ! [ -a "$KERN_IMG" ]; then
	tg_erlog && error_sticker
	exit 1
else
	make_flashable
	tg_pushlink
fi
