# Wire™

[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![CircleCI](https://circleci.com/gh/wireapp/wire-ios-protos.svg?style=shield)](https://circleci.com/gh/wireapp/wire-ios-protos) [![codecov](https://codecov.io/gh/wireapp/wire-ios-protos/branch/develop/graph/badge.svg)](https://codecov.io/gh/wireapp/wire-ios-protos)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# wire-ios-protos

This framework is part of Wire iOS SyncEngine. Additional documentation is available in the [Wire iOS wiki](https://github.com/wireapp/wire-ios/wiki).

The wire-ios-protos framework contains precompiled protocol buffer definitions for objective-c / swift and some convenience methods around them.

## How to build

This framework is using Carthage to manage its dependencies. To pull the dependencies binaries, `run carthage bootstrap --platform ios`.

You can now open the Xcode project and build.

You need protocol buffer objective-C installed. Follow the instructions here: https://github.com/alexeyxo/protobuf-objc
