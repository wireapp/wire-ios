# Encryption at Rest

Protect sensitive persisted data while the app in inactive.  

## Overview

Encryption at Rest (EAR) is a feature to protect sensitive data stored on the device while the app is "at rest", that is, when the app is not actively running. Most, if not all of the sensitive data is stored in Core Data. Since Core Data does not provide encryption at rest functionality, we must implement this functionality ourselves.

By definition, data that is encrypted at rest is persisted in encrypted form and, when it is decrypted, exists is only in memory. To achieve this, the data needs to be encrypted when it is stored in the database and decrypted when it is retrieved from the database.

TODO: diagram showing this flow

### Encryption keys

When encryption at rest is enabled, several keys are generated: the primary keys, the secondary keys, and database key.

The primary keys are a public private key pair generated within a highly secure vault called the Secure Enclave, located in a separate security chip on the device. The public key is used for encryption and is easily accessible, whereas the private key is used for decryption and can only be accessed once the user has confirmed their identity via biometric authentication. This ensures  the correct user is actively present.

The secondary keys are the same as the primary keys, with the one difference that the private key does not require user presence, but only that the device has been unlocked once after boot. This means that the key is also accessible without the user being present, such as when the app is operating in the background.

The database key is some randomly generated data that is stored in the keychain as a generic password. The database key is itself encrypted at rest: it is encrpyted by the primary public key when stored in the keychain, and decrypted by the primary private key when retrieved from the keychain. This means that the database key is only useable after successful biometric authentication.

TODO: graphic

### Which data is encrypted at rest?

All data this is deemed sensitive is encrypted at rest. This includes all messages sent and received and all stored update event data (which may contain user data) that is received from the backend and is awaiting processing.

Messages are encrypted with the **database key** prior to being stored in the message database. The same key is used to decrypt the messages after it has been retrieved from the database.

TODO: what is the encryption algorithm?

Stored update events are encrypted using one of the public keys prior to being inserted in the event database. The reason why it is not encrypted with the database key is because the database key is only accessible when the app is in the foreground and the user is present. This would prevent update events received in the background from being encrypted. The public key however is always accessible. 

The stored update events are decrypted with the associated private key. If this is the primary key, then the event can only be decrypted (and subsequently processed) when the app is in the foreground with user presence. If it is the secondary key, the event can be decrypted and processed without user presence in the background.

For this reason, only call events are encrypted and decrypted using the secondary keys, since these events need to be processed while the app is operating in the background during CallKit calls. 

### Migration

TODO: migrate toward, migrate away from, backup, restore.

Keys are not part of backup, hence migration.
