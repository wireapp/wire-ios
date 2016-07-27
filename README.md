# Wire™
[![Build Status](https://travis-ci.org/wireapp/wire-ios-mocktransport.svg?branch=develop)](https://travis-ci.org/wireapp/wire-ios-mocktransport)

![Wire logo](https://github.com/wireapp/wire/blob/master/assets/logo.png?raw=true)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# wire-ios-mocktransport

This framework is part of Wire iOS SyncEngine. Visit [iOS SyncEngine repository](http://github.com/wireapp/zmessaging-cocoa) for an overview of the architecture.

The wire-ios-mocktransport framework helps us mock the requests to our backend during integration tests.

### How to build

This framework is using Carthage to manage its dependencies. To pull the dependencies binaries, `run carthage bootstrap --platform ios`.

You can now open the Xcode project and build.
