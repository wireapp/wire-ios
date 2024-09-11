# ``WireDomain``

Domain layer containing business logic.

## Overview

The WireDomain framework provides the business logic components of the app: Repositories, Use cases or specific components related to Event Processing.

It depends on WireAPI and for the time being other older frameworks like WireDataModel and WireTransport.

> Note: In order to make it work with the old stack (WireSyncEngine...), it has been created as a Xcode project producing a framework. Once the old stack is replaced it could become a Swift Package.

## Topics

### Conversations

- <doc:conversations>
- ``ConversationRepository``
- ``ConversationLocalStore``

### Federation

- <doc:federation>

### Repositories

- ``UserRepository``
- ``ConversationRepository``

### UseCases

- TBD
