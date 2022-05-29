#!/usr/bin/bash
# /src is the kernel source location
# /build is a tmpfs
#
# First argument must be the name of a defconfig (e.g. davinci or davinci-hardened)

mkdir /build/toolchain
cd /build/toolchain
curl https://ftp.travitia.xyz/clang/clang-latest.tar.xz | tar -xJ

git clone --single-branch -b main --depth 1 https://github.com/DavinciCodeOS/AnyKernel3.git /build/anykernel

export PATH="/build/toolchain/bin:$PATH"
export KBUILD_BUILD_USER=adrian
export KBUILD_BUILD_HOST=syndra

cd /src
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 $1_defconfig

# Build once for EROFS /system
make -j$(nproc) \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-

cp /src/out/arch/arm64/boot/dtb.img /src/out/arch/arm64/boot/dtb_erofs.img

# Revert the EROFS patch temporarily
git am -3 patches/revert-erofs.patch

# Build again for EXT4 /system
make -j$(nproc) \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-

# Revert the commit cleanly
INITIAL_COMMIT_HASH=$(git log -n 1 --skip 1 --pretty=format:"%H")
git reset --hard $INITIAL_COMMIT_HASH

FILENAME=VantomSyndra-$1-$(date +"%Y%m%d-%H%M").zip
FILENAME_RECOVERY=vantom-$1-$(date +"%Y%m%d-%H%M")-recovery.zip

cd /build/anykernel
rm -rf .git README.md
cp /src/out/arch/arm64/boot/Image.gz .
cp /src/out/arch/arm64/boot/dtbo.img .
cp /src/out/arch/arm64/boot/dtb_erofs.img dtb_erofs.img
cp /src/out/arch/arm64/boot/dtb.img dtb.img
zip -r9 $FILENAME ./
mv $FILENAME /src/out/

mkdir /build/recovery
cd /build/recovery
cp /src/out/arch/arm64/boot/Image.gz-dtb .
cp /src/out/arch/arm64/boot/dtbo.img .
zip -r9 $FILENAME_RECOVERY ./
mv $FILENAME_RECOVERY /src/out/

echo "Done building. Check out/$FILENAME for the installable ZIP and out/$FILENAME_RECOVERY for the recovery kernel."
