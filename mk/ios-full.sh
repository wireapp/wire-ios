#
# Copyright (c) 2013-2015
# Frank Denis <j at pureftpd dot org>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

# Variant of `ios.sh` from libsodium that builds the "full"
# libsodium API, i.e. without `--enable-minimal`.
#
#! /bin/sh
#
#  Step 1.
#  Configure for base system so simulator is covered
#
#  Step 2.
#  Make for iOS and iOS simulator
#
#  Step 3.
#  Merge libs into final version for xcode import

export PREFIX="$(pwd)/libsodium-ios"
export IOS32_PREFIX="$PREFIX/tmp/ios32"
export IOS64_PREFIX="$PREFIX/tmp/ios64"
export SIMULATOR32_PREFIX="$PREFIX/tmp/simulator32"
export SIMULATOR64_PREFIX="$PREFIX/tmp/simulator64"
export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"5.1.1"}
export IOS_VERSION_MIN=${IOS_VERSION_MIN-"5.1.1"}
export XCODEDIR=$(xcode-select -p)

mkdir -p $SIMULATOR32_PREFIX $SIMULATOR64_PREFIX $IOS32_PREFIX $IOS64_PREFIX || exit 1

# Build for the simulator
export BASEDIR="${XCODEDIR}/Platforms/iPhoneSimulator.platform/Developer"
export PATH="${BASEDIR}/usr/bin:$BASEDIR/usr/sbin:$PATH"
export SDK="${BASEDIR}/SDKs/iPhoneSimulator.sdk"

## i386 simulator
export CFLAGS="-O2 -arch i386 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
export LDFLAGS="-arch i386 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"

make distclean > /dev/null

./configure --disable-shared \
            --prefix="$SIMULATOR32_PREFIX" || exit 1

make -j3 install || exit 1

## x86_64 simulator
export CFLAGS="-O2 -arch x86_64 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
export LDFLAGS="-arch x86_64 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"

make distclean > /dev/null

./configure --disable-shared \
            --prefix="$SIMULATOR64_PREFIX"

make -j3 install || exit 1

# Build for iOS
export BASEDIR="${XCODEDIR}/Platforms/iPhoneOS.platform/Developer"
export PATH="${BASEDIR}/usr/bin:$BASEDIR/usr/sbin:$PATH"
export SDK="${BASEDIR}/SDKs/iPhoneOS.sdk"

## 32-bit iOS
export CFLAGS="-Oz -mthumb -arch armv7 -arch armv7s -isysroot ${SDK} -mios-version-min=${IOS_VERSION_MIN}"
export LDFLAGS="-mthumb -arch armv7 -arch armv7s -isysroot ${SDK} -mios-version-min=${IOS_VERSION_MIN}"

make distclean > /dev/null

./configure --host=arm-apple-darwin10 \
            --disable-shared \
            --prefix="$IOS32_PREFIX" || exit 1

make -j3 install || exit 1

## 64-bit iOS
export CFLAGS="-Oz -arch arm64 -isysroot ${SDK} -mios-version-min=${IOS_VERSION_MIN}"
export LDFLAGS="-arch arm64 -isysroot ${SDK} -mios-version-min=${IOS_VERSION_MIN}"

make distclean > /dev/null

./configure --host=arm-apple-darwin10 \
            --disable-shared \
            --prefix="$IOS64_PREFIX" || exit 1

make -j3 install || exit 1

# Create universal binary and include folder
rm -fr -- "$PREFIX/include" "$PREFIX/libsodium.a" 2> /dev/null
mkdir -p -- "$PREFIX"
lipo -create \
  "$SIMULATOR32_PREFIX/lib/libsodium.a" \
  "$SIMULATOR64_PREFIX/lib/libsodium.a" \
  "$IOS32_PREFIX/lib/libsodium.a" \
  "$IOS64_PREFIX/lib/libsodium.a" \
  -output "$PREFIX/libsodium.a"
mv -f -- "$IOS32_PREFIX/include" "$PREFIX/"

echo
echo "libsodium has been installed into $PREFIX"
echo
file -- "$PREFIX/libsodium.a"

# Cleanup
rm -rf -- "$PREFIX/tmp"
make distclean > /dev/null
