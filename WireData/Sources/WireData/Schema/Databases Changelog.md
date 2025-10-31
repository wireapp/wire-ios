# Databases Changelog

As it is hard to spot changes from version to version of database models (.xcdatamodeld), here's a changelog highlighting changes per version.

## Special changes

### Moving of `zmessaging` & `ZMEventModel` to `WireData` SPM target

* Move `zmessaging` & `ZMEventModel` to `WireData` SPM target while keeping managed object subclasses in `WireDataModel` project target. This is an intermediary state. Eventually all managed object subclasses should be moved to `WireData` target. To achieve this, in **ALL VERSIONS** of `zmessaging` the _Module_ field in the Data Model Inspector was set to `WireDataModel` for non obj-c based entities. The same changes were applied to `ZMEventModel`. These changes did not require a migration. 

## zmessaging

### 2.131.0

* added `typeValue` to the `User` entity with default value -1

### 2.130.0

* added `UnknownMessage` entity

### 2.129.0

* added `cellsState` attribute on the Conversation entity

### 2.128.0

* added `wireCellsLocalAssets` entity

### 2.127.0

* renamed `asyncStreamCapable` attribute to `isConsumableNotificationsCapable` the UserClient entity

### 2.126.0

* added `WireCellsMessageAttachmentDraft` entity
* added `wireCellsMessageAttachmentDrafts` attribute to Conversation entity
* added `cellName` attribute to Conversation entity

### 2.125.0

* added `asyncStreamCapable` attribute on the UserClient entity

### 2.124.0

* added `migratedToMLS` attribute on the Conversation entity

### 2.123.0

* added `groupType` attribute on the Conversation entity
* added `privateChannelPermission` attribute on the Conversation entity

### 2.122.0

* Remove `ToDeleted` entity from 2.120.0
* Cleanup `needsToUploadSignalingKeys`, `apsVerificationKey`, `apsDecryptionKey` from `UserClient`

### 2.121.0

Removed `pushToken` attribute from `UserClient`.

### 2.120.0

* Added `ToDeleted` entity

PostAction to fix issue with federation migration. It triggers a resyncResources to make sure users and conversations get the domain.

### 2.119.0

* removed phoneNumber from User entity

PostAction to fix duplicate 1-1 proteus conversations

### 2.118.0

* added `shouldExpire` attribute on the Messaging entity

### 2.117.0

* added `ciphersuite` attribute on the Conversation entity

### 2.116.0

* added `isPendingInitialFetch` attribute on the Conversation entity

PostAction to fill IsPendingInitialFetch attribute to false (in order to fix system messages - https://github.com/wireapp/wire-ios/pull/1266)

### 2.115.0

* removed one-to-one relationship `Connection.conversation` <-> `Conversation.connection`

### 2.114.0

* added `mlsVerificationStatus` attribute of type Integer 16, default value 0
* added `supportedProtocols` attribute of type `Transformable` with valueTransformerName `ExtendedSecureUnarchiveFromData` on `User`
* added one-to-one relationship (optional nullify) `User.oneOnOneConversation` <-> `Conversation.oneOnOneUser` (optional nullify)

PostAction to migrate oneOneOneConversations

### 2.113.0

* added `lastActiveDate` attribute of type `Date` on `UserClient`

### 2.112.0

* removed `fingerprint` attribute from `UserClient`

### 2.111.0

* added `primaryKey` attribute of type `String` on `Conversation`
* added `primaryKey` attribute of type `String` on `User`
* added `primaryKey` attribute of type `String` on `Team`
* added uniqueness constraint `primaryKey` on `User`
* added uniqueness constraint `remoteIdentifier_data` on `Team`
* added uniqueness constraint `primaryKey` on `Conversation`
* make `conversation` relationship of `ParticipantRole` optional 
* make `user` relationship of `ParticipantRole` optional

~~heavy weight migration MappingModel_2.110-2.111~~ - preAction to fill primaryKey

* add custom policy TeamToTeam: `WireDataModel.DuplicateTeamsMigrationPolicy`
* add custom policy ConversationToConversation: `WireDataModel.DuplicateObjectsMigrationPolicy` 
* add custom policy UserToUser: `WireDataModel.DuplicateObjectsMigrationPolicy`

### 2.110.0

* removed `activationLocationLatitude` attribute from `UserClient`
* removed `activationLocationLongitude` attribute from `UserClient`
 
## ZMEventModel

### 6.0

* add new `StoredUpdateEventEnvelope` entity to persist new `WireNetwork.UpdateEventEnvelope` instances. This replaces `StoredUpdateEvent` which can be deleted after some time.

### 5.0

* add new eventHash attribute of type Int64 on `StoredUpdateEvent`

### 4.0

TBD

