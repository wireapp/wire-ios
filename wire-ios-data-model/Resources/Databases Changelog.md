# Databases Changelog

As it is hard to spot changes from version to version of database models (.xcdatamodeld), here's a changelog highlighting changes per version.

## zmessaging

### 2.114.0

* added `mlsVerificationStatus` attribute of type Integer 16, default value 0
* added `supportedProtocols` attribute of type `Transformable` with valueTransformerName `ExtendedSecureUnarchiveFromData` on `User`
* added one-to-one relationship (optional nullify) `User.oneOnOneConversation` <-> `Conversation.oneOnOneUser` (optional nullify)
* removed one-to-one relationship `Connection.conversation` <-> `Conversation.connection`

#### heavy weight migration MappingModel_2.113-2.114

* add custom policy UserToUser: `WireDataModel.OneOnOneConversationMigrationPolicy`

### 2.113.0

* added `lastActiveDate` attribute of type `Date` on `User`

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

#### heavy weight migration MappingModel_2.113-2.114

* add custom policy TeamToTeam: `WireDataModel.DuplicateTeamsMigrationPolicy`
* add custom policy ConversationToConversation: `WireDataModel.DuplicateObjectsMigrationPolicy` 
* add custom policy UserToUser: `WireDataModel.DuplicateObjectsMigrationPolicy`

### 2.110.0

* removed `activationLocationLatitude` attribute from `UserClient`
* removed `activationLocationLongitude` attribute from `UserClient`
 
## ZMEventModel

### 4.0

TBD

