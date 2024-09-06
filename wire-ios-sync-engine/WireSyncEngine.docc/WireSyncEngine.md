# ``WireSyncEngine``

Power the operation of the Wire iOS app.

## Overview

The WireSyncEngine framework provides the logical functionality necessary to run the Wire
iOS app. In contains all the logic and dependencies necessary to log in, create and manage
conversations, send and receive encrypted messages, among many other things.

Its main responsibility is to set up the dependency graph and combine components from
other frameworks to construct the functionality of the app. For instance, it depends on
`WireRequestStrategy` for generating and processing API requests and responses, `WireTransport`
for communication with the backend, and `WireDataModel` for local persistence.

## Topics

### Essentials

Here we can find some important classes.

- ``SessionManager``
- ``ZMUserSession``

### MLS

- <doc:MLS>
