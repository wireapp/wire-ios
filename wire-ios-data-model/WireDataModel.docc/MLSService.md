# ``WireDataModel/MLSService``

>Note: The responsibilities of this service are too broad and should be broken down into smaller classes.

## Topics

### Managing groups

- ``createGroup(for:parentGroupID:)``
- ``createSelfGroup(for:)``
- ``establishGroup(for:with:)``
- ``joinGroup(with:)``
- ``joinNewGroup(with:)``
- ``performPendingJoins()``
- ``wipeGroup(_:)``
- ``conversationExists(groupID:)``

### Adding / Removing members

- ``addMembersToConversation(with:for:)``
- ``removeMembersFromConversation(with:for:)``

### Managing subgroups

- ``createOrJoinSubgroup(parentQualifiedID:parentID:)``
- ``createGroup(for:parentGroupID:)``
- ``leaveSubconversation(parentQualifiedID:parentGroupID:subconversationType:)``
- ``leaveSubconversationIfNeeded(parentQualifiedID:parentGroupID:subconversationType:selfClientID:)``
- ``deleteSubgroup(parentQualifiedID:)``
- ``subconversationMembers(for:)``

### Encryption and decryption

- ``encrypt(message:for:)``
- ``decrypt(message:for:subconversationType:)``

### Welcome message

- ``processWelcomeMessage(welcomeMessage:)``

### Pending propoals

- ``commitPendingProposalsIfNeeded()``
- ``commitPendingProposals(in:)``

### Key material

- ``updateKeyMaterialForAllStaleGroupsIfNeeded()``

### Key packages

- ``uploadKeyPackagesIfNeeded()``

### Out of sync groups

- ``repairOutOfSyncConversations()``
- ``fetchAndRepairGroup(with:)``

### Epoch

- ``generateNewEpoch(groupID:)``
- ``onEpochChanged()``
- ``epochChanges()``

### Conference info

- ``generateConferenceInfo(parentGroupID:subconversationGroupID:)``
- ``onConferenceInfoChange(parentGroupID:subConversationGroupID:)``

### Proteus to MLS migration

- ``startProteusToMLSMigration()``

### E2EI (end-to-end identity)

- ``onNewCRLsDistributionPoints()``
