# Databases Changelog

As it is hard to spot changes from version to version of database models (.xcdatamodeld), here's a changelog highlighting changes per version.

## zmessaging

### 2.119.0

* removed phoneNumber from User entity

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

* add new `StoredUpdateEventEnvelope` entity to persist new `WireAPI.UpdateEventEnvelope` instances. This replaces `StoredUpdateEvent` which can be deleted after some time.

### 5.0

* add new eventHash attribute of type Int64 on `StoredUpdateEvent`

### 4.0

TBD

