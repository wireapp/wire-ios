# Wire™

![Wire logo](https://github.com/wireapp/wire/blob/master/assets/logo.png?raw=true)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

#ZMessaging-cocoa

ZMessaging-cocoa is used as part of the [Wire iOS client](http://github.com/wireapp/wire-ios).

*ZMessaging-cocoa* is the top-most layer of the iOS *sync engine*, and it is using on a number of lower-level frameworks. *ZMessaging-cocoa* and the lower-lever frameworks constitute the iOS *sync engine*, as illustrated in the following picture.

![iOS architecture](https://github.com/wireapp/wire/blob/master/assets/ios-se-architecture.png?raw=true)

The iOS sync engine is developed in a mix of Objective-C and Swift (and just a handful of classes in Objective-C++). It is a result of a long development process that was started in Objective-C when Swift was not yet available. In the past year, parts of it have been written or rewritten in Swift. Going forward, expect new functionalities to be developed almost exclusively in Swift.

## How to build

iOS SyncEngine is using [Carthage](https://github.com/Carthage/Carthage) to manage dependencies. To pull the dependencies binaries, run `carthage bootstrap —-platform ios` .

You can now open the Xcode project and build.

## Repositories

- [zmc-utilities](https://github.com/wireapp/zmc-utilities): implements common data structures, algorithms (such as symmetric encryption) and application environment detection (internal or public build / production or staging backend)
- [zmc-system](https://github.com/wireapp/zmc-system): covers interaction with ASL (Apple System Log), profiling and wrappers of some foundation/cocoa classes
- [zmc-transport](https://github.com/wireapp/zmc-transport): abstracts the network communication with the backend: handles authentication of requests, network failures and retries transparently
- [zmc-testing](https://github.com/wireapp/zmc-testing): testing utilities
- [zmc-protos](https://github.com/wireapp/zmc-protos): precompiled protocol buffer definitions for objective-c / swift and some convenience methods around them
- [zmc-mocktransport](https://github.com/wireapp/zmc-mocktransport): simulates the entire network component (including backend behaviour) for testing purposes
- [zmc-images](https://github.com/wireapp/zmc-images): performs rotation and scaling of images
- [zmc-cryptobox](https://github.com/wireapp/zmc-cryptobox): higher level convenience wrappers around cryptobox for iOS
- [zmc-data-model](https://github.com/wireapp/zmc-data-model): Core Data model and entity classes
- [cryptobox-ios](https://github.com/wireapp/cryptobox-ios): iOS binaries for cryptobox
- [zmc-linkpreview](http://github.com/wireapp/zmc-linkpreview): OpenGraph processor (fetching and parsing)
