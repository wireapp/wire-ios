# Wire™
[![Build Status](https://travis-ci.org/wireapp/wire-ios-cryptobox.svg?branch=develop)](https://travis-ci.org/wireapp/wire-ios-cryptobox)

![Wire logo](https://github.com/wireapp/wire/blob/master/assets/logo.png?raw=true)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# Cryptobox for iOS

This framework is used in [Wire iOS SyncEngine](http://github.com/wireapp/zmessaging-cocoa).

This project provides for cross-compilation of [cryptobox](https://github.com/shared-secret/cryptobox) for iOS, currently only in the form of static libraries.

## Integrating Objective-C Wrapper
You can integrate Objective-C Wrapper (Cryptobox.framework) using Carthage.
When Carthage will build it first time it will also build `libcryptobox.a` and `libsodium.a` in `Carthage/Checkouts/cryptobox-ios/build` with `libs` and `include` subfolders. So you can just add these paths to Libraries Search Paths and Headers Search Paths of your project.
