# ``WireDataModel``

Provides the persistence layer for Wire. 

## Overview

WireDataModel provides the persistence for Wire, powered by Core Data. As such it contains the database schemas, the ``CoreDataStack`` to manage access to the database, and all the managed object subclasses that represent entities in the database (e.g ``ZMConversation`` and ``ZMUser``).





> Note: WireDataModel also contains a lot of business logic in the form of extensions on managed object subclasses. These should be factored out of the persistence layer.

## Topics

### Encryption at Rest

- <doc:encryption-at-rest>
- ``EARService``
- ``EARServiceDelegate``
- ``EARKeyGenerator``

### Entities

These managed object subclasses are frequently used in the business logic and comprise the fundamental building block of Wire's model:

- ``ZMConversation``
- ``ZMUser``
- ``UserClient``
- ``ZMClientMessage``
- ``ZMAssetClientMessage``
- ``Team``
- ``Member``
