# Wire™
[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![Build Status](https://travis-ci.org/wireapp/wire-ios-cryptobox.svg?branch=develop)](https://travis-ci.org/wireapp/wire-ios-cryptobox)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# Cryptobox for iOS

This framework is part of Wire iOS SyncEngine. Visit [iOS SyncEngine repository](http://github.com/wireapp/wire-ios-sync-engine) for an overview of the architecture.

This project provides for cross-compilation of [cryptobox](https://github.com/wireapp/cryptobox) for iOS, currently only in the form of static libraries.

## Integrating Objective-C Wrapper
You can integrate Objective-C Wrapper (Cryptobox.framework) using Carthage.
When Carthage will build it first time it will also build `libcryptobox.a` and `libsodium.a` in `Carthage/Checkouts/cryptobox-ios/build` with `libs` and `include` subfolders. So you can just add these paths to Libraries Search Paths and Headers Search Paths of your project.
