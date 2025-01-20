# Conversations  

## Overview

Conversations are containers of messages: messages can only be sent to a conversation. Each conversation has an identifier, a list of participants ("members"), a type and other metadata. Only members of a conversation can send messages in that conversation.
There are different types of conversation, and in addition we have the concept of subgroups.

### What is a `connection` conversation ?

In order for two users to become connected, one of them performs a connection request and the other one accepts it.
When the connection is accepted, the other user joins the conversation.
Connections are like “friend requests” on other products.

### What is a `self` conversation ?

The self conversation is a conversation with exactly one user. This is each user’s private conversation. 
Every user has exactly one self-conversation. The identifier of the self-conversation for one user is the same as the user identifier.
The self conversation is not displayed anywhere in the UI. This conversation is used to send messages to all devices of a given user. 
If a device needs to synchronize something with all the other devices of this user, it will send a message here.

### What is a `group` conversation ?

A group conversation can contain a group of users.
All members in a group are assigned a role, either when the group is created or by the member who adds a new user to the group.
The roles define which actions a user is allowed to perform within the group.
There are two pre-defined roles: `wire_admin` and `wire_member`
The creator of a group will by default be assigned the `wire_admin` role.
In addition to these pre-defined roles a team can potentially define new roles with a different set of actions.

### What is a `1:1` conversation ?

The implementation differs between Proteus-based conversations and MLS-based conversations.

__Proteus (not in a team)__

When a connection is created it also creates an associated conversation. As the name implies a 1:1 conversation is always between two users which can't be changed.

__Proteus (in a team)__

A team 1:1 is a conversation between two users that belong to the same team.

__MLS (whether in team or not in team)__

MLS 1:1 conversations always implicitly exist when there’s a connection between two users, either via a connection or indirectly when the two users belong to the same team.
Therefore the conversation doesn’t need to be created but the underlying MLS group needs to be established.
