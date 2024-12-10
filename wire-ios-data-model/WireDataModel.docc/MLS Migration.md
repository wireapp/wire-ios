# MLS Migration

MLS migration is about migrating existing proteus conversations to MLS. Group conversations are migrated following one strategy, whereas 1:1 conversations are migrated following another.

## Group conversations

For group conversations, the migration is designed to be done over a period of time defined by a starting time and an optional finalization time. During this period, the conversations transition to the ``MessageProtocol/mixed`` protocol until they are ready to be fully migrated to the ``MessageProtocol/mls`` protocol.

Conversations in `.mixed` mode use Proteus to encrypt and decrypt messages, and retain the capacity to add and remove members from the Proteus part of the conversation, whilst also maintaining their MLS group counterpart. This means that they support operations such as committing pending proposals and updating key material.
Once every member of the conversation is capable of supporting MLS, or once the finalization time is reached, the conversation is fully migrated to MLS.

The configuration of the migration is defined by the backend and is fetched by the client. The client is responsible for starting the migration at the right time and for finalizing it when the time comes. The configuration is defined in ``Feature/MLSMigration``

The ``ProteusToMLSMigrationCoordinator`` class is responsible for managing the migration of group conversations.

Documentation about the implementation details are available on [Confluence](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/746488003/Proteus+to+MLS+Migration).

![Diagram about the migration of group conversations](MLS-group-migration)

## 1:1 conversations

Since 1:1 conversations have at most 2 participants there’s no need for turning conversation to `.mixed` mode and initialising the MLS group at this point. We can simply wait until both users support MLS, establish a 1:1 MLS conversation and join its MLS group.

The migration of 1:1 conversations is done by the ``OneOnOneResolver`` class. 

Documentation about implementation details can be found [here](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/811958286/Use+case+Migration+of+1+1+conversation+Proteus+to+MLS+migration)

