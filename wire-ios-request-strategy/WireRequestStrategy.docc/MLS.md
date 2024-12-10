# MLS

This document covers the classes related to MLS in WireRequestStrategy. For a more general overview of MLS, see the documentation in WireDataModel.

Most objects here are responsible for generating network requests and processing responses and update events.

### Generating requests

The ``MLSRequestStrategy`` class is responsible for setting up the action handlers for MLS requests. It will be notified when new requests are allowed and will in turn notify the action handlers.

The action handlers are located in `"Request Strategies/MLS/Actions"`

### Sending messages

The ``MessageSender`` class is responsible for encrypting and sending messages using Proteus or MLS, based on the conversation's `messageProtocol`. 

MLS messages should conform to the ``MLSMessage`` protocol.

### Event processing

The ``EventDecoder`` is responsible for decrypting and storing update events. 

We may receive two types of MLS events: 
- A welcome message - `ZMUpdateEventType.conversationMLSWelcome`
- An MLS message - `ZMUpdateEventType.conversationMLSMessageAdd`

These events will be decrypted and stored by the ``EventDecoder``, in the `EventDecoder+MLS` extension.

