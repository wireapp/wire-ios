# MLS 

## What is MLS (Messaging Layer Security)?

Messaging Layer Security (MLS) is a protocol developed to provide end-to-end encryption for group messaging. MLS enables secure communications in large and dynamic groups. 

Key features of MLS include:
- **Scalability**: Handles large groups with many participants.
- **Performance**: Reduces overhead in managing keys and group membership changes.
- **Forward Secrecy and Post-Compromise Security**: Protects past and future messages, even if a participant’s key is compromised.

Compared to Proteus, MLS is more suitable to handle large groups and will eventually replace Proteus after a transition period. Currently, both protocols are supported.

## What is Proteus?

Proteus is the legacy end-to-end encryption protocol used by Wire. It implements the **double-ratchet algorithm** to manage encryption keys and enables **forward secrecy** and **post-compromise** security.
It's ideal for secure direct communication between individuals but does not scale well for large groups.

## External resources

The videos are great starting points to understand the concepts behind MLS and Proteus. And the MLS standard can be used as a reference to understand the protocol in more detail.

- video about [Double ratchet algorithm](https://www.youtube.com/watch?v=7uEeE3TUqmU)
- video about [Messaging Layer Security](https://www.youtube.com/watch?v=FESp2LHd42U)
- [MLS standard](https://datatracker.ietf.org/doc/html/rfc9420)

Confluence also has many **use cases** descibing implementation details for each feature

## Glossary

This glossary covers a handful of terms specific to MLS that are being used throughout the codebase.

- **Group / Conversation**: A collection of members that communicate with each other using MLS. __Note__: there are also conversations that use the Proteus protocol. They are typically referred to as "conversations" while in MLS the terms "group" and "conversation" are used interchangeably.
- **Subgroup / Subconversation**: A subset of members within a larger group, created to facilitate more focused or secure communication among a subset of the original members. Typically used for conferences to share sensitive information about a call with its participants only, and not with the rest of the group. Subgroups maintain their own cryptographic state (epoch and keys).
- **Group ID**: A unique identifier for a group or a subgroup.
- **Epoch**: A specific version or state of the group, including its cryptographic keys. Represented by an integer value, it starts at 0 and increments with each change (like adding or removing members).
- **Proposal**: Suggested changes to the group’s state, such as adding or removing members, or updating cryptographic keys. Proposals must be included in a commit to take effect.
- **Commit**: An operation that finalizes a proposed change (proposal) to the group. It applies these changes and transitions the group to a new epoch.
- **Welcome message**: A message sent to new members joining an existing group. It contains the necessary information, including cryptographic keys, to synchronize the new member with the current state of the group.
- **Ciphersuite**: A specific set of cryptographic algorithms used to secure communications within a group. It defines the algorithms for key exchange, encryption, message authentication, and hashing, ensuring that all participants in the group use the same cryptographic methods.
- **Key package**: A data structure that contains a public key, supported ciphersuites, and other necessary cryptographic material for a client. It is used during the initial setup of a group or when a new member joins the group.

## Core crypto

Core crypto is a wrapper on top of OpenMLS aimed to provide an ergonomic API to create, manage and interact with MLS groups. It abstracts MLS and Proteus. 

The library is written in Rust and provides Swift bindings generated with FFI. The dependency is distributed as an `xcframework` and is managed with Carthage. [See documentation](https://wireapp.github.io/core-crypto/core_crypto/index.html)

MLS functionalities provided by core crypto include:

- Group and subgroup management (create, join, leave, delete)
- Adding / Removing group members
- Encryption and decryption of messages
- Key management
- Epoch management
- E2EI (End-to-end identity)

## MLS Groups / Conversations

MLS conversations are referred through the codebase as "conversation" or "group". These terms are often used interchangeably but their origins differ: one comes from how conversations are represented in Core Data, and the other comes from Core Crypto.

In Core Data, conversations are represented by ``ZMConversation`` objects. They contain metadata about the conversations such as their remote identifier, domain, name, etc... 

They're used to represent both MLS and Proteus conversations. The protocol they use is represented by the ``ZMConversation/messageProtocol`` property.

``ZMConversation`` objets have a couple of optional properties that are specific to MLS conversations, such as:
- ``ZMConversation/mlsGroupID``: The identifier of the group
- ``ZMConversation/epoch``: The epoch of the group
- ``ZMConversation/epochTimestamp``: The timestamp of the epoch. Represents the last time the epoch changed
- ``ZMConversation/ciphersuite``: The ciphersuite used by the group
- ``ZMConversation/commitPendingProposalDate``: The date when the pending proposals should be committed
- ``ZMConversation/mlsStatus``: The status of the group
- ``ZMConversation/mlsVerificationStatus``: The verification status of the group. Specific to end-to-end identity (E2EI)

If the conversation's message protocol is MLS, then these properties should be present.

The `ZMConversation` counterparts on Core Crypto's side are groups. MLS groups are created and managed using the Core Crypto library. We use ``MLSGroupID`` structs to identify groups between the iOS project and Core Crypto.


## MLS Subgroups / Subconversations

Similarly to MLS conversations, the subconversations are also interchangeably referred to as "subgroup" or "subconversations", but they aren't managed by Core Data. They're either represented by the ``MLSSubgroup`` struct when interacting with the backend, or can be identified using their ``MLSGroupID`` or the ``MLSGroupID`` (and sometimes ``QualifiedID``) of their parent conversations. 

Parent conversations are MLS conversations and thus are represented by ``ZMConversation`` objects. 
