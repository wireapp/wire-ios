# ``Wire``

The Wire app.

## Overview

Wire-iOS is the project for the Wire app.


## Share Extension 

The `WireShareExtension` provides share images, links, messages etc. from system's share sheets.


## Notification Extension

The `WireNotificationExtension` enriches push notifications and fetches update events.


## Testing

Wire-iOS has 3 different testing targets:

* **Wire-iOS-Tests:** (legacy) includes UnitTests and SnapshotTests.
* **Wire-iOS UnitTests:** includes **only** new UnitTests. 
* **WireUITests:** contains end-to-end tests with XCUITests. This is used for critical flows.

Note: As the first (legacy) target grown, we decided to split SnapshotTests from UnitTests.

### Sourcery Mocks
The project uses [Sourcery](https://github.com/krzysztofzablocki/Sourcery) to generate mocks and embed it in a custom SPM plugin `SourceryPlugin`.

You can find a examples of how to use the mocks in the [official documentation](https://krzysztofzablocki.github.io/Sourcery/mocks.html).
