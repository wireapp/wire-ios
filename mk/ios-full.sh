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
export IOS64_PREFIX="$PREFIX/tmp/ios64"
export SIMULATOR64_PREFIX="$PREFIX/tmp/simulator64"
export SIMULATORARM64_PREFIX="$PREFIX/tmp/simulatorArm64"
export XCODEDIR=$(xcode-select -p)

xcode_major=$(xcodebuild -version|egrep '^Xcode '|cut -d' ' -f2|cut -d. -f1)
if [ $xcode_major -ge 13 ]; then
  export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"15.0.0"}
  export IOS_VERSION_MIN=${IOS_VERSION_MIN-"6.0.0"}
else
  export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"5.1.1"}
  export IOS_VERSION_MIN=${IOS_VERSION_MIN-"5.1.1"}
fi

mkdir -p $SIMULATOR64_PREFIX $IOS64_PREFIX || exit 1

# Build for the simulator
export BASEDIR="${XCODEDIR}/Platforms/iPhoneSimulator.platform/Developer"
export PATH="${BASEDIR}/usr/bin:$BASEDIR/usr/sbin:$PATH"
export SDK="${BASEDIR}/SDKs/iPhoneSimulator.sdk"

## arm64 simulator
export CFLAGS="-O2 -arch arm64 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN} -flto"
export LDFLAGS="-arch arm64 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN} -flto"

make distclean > /dev/null

./configure --host=arm-apple-darwin20 \
            --disable-shared \
            --prefix="$SIMULATORARM64_PREFIX" || exit 1

make -j3 install || exit 1

## x86_64 simulator
export CFLAGS="-O2 -arch x86_64 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN} -flto"
export LDFLAGS="-arch x86_64 -isysroot ${SDK} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN} -flto"

make distclean > /dev/null

./configure --host=x86_64-apple-darwin10 \
            --disable-shared \
            --prefix="$SIMULATOR64_PREFIX"

make -j3 install || exit 1

# Build for iOS
export BASEDIR="${XCODEDIR}/Platforms/iPhoneOS.platform/Developer"
export PATH="${BASEDIR}/usr/bin:$BASEDIR/usr/sbin:$PATH"
export SDK="${BASEDIR}/SDKs/iPhoneOS.sdk"

## 64-bit iOS
export CFLAGS="-O2 -arch arm64 -isysroot ${SDK} -mios-version-min=${IOS_VERSION_MIN} -flto"
export LDFLAGS="-arch arm64 -isysroot ${SDK} -mios-version-min=${IOS_VERSION_MIN} -flto"

make distclean > /dev/null

./configure --host=arm-apple-darwin10 \
            --disable-shared \
            --prefix="$IOS64_PREFIX" || exit 1

make -j3 install || exit 1

# Create universal binary and include folder
rm -fr -- "$PREFIX/include" "$PREFIX/libsodium.a" 2> /dev/null
mkdir -p -- "$PREFIX"
lipo -create \
  "$SIMULATOR64_PREFIX/lib/libsodium.a" \
  "$SIMULATORARM64_PREFIX/lib/libsodium.a" \
  "$IOS64_PREFIX/lib/libsodium.a" \
  -output "$PREFIX/libsodium.a"

echo
echo "libsodium has been installed into $PREFIX"
echo
file -- "$PREFIX/libsodium.a"

# Cleanup
rm -rf -- "$PREFIX/tmp"
make distclean > /dev/null
