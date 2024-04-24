# Encryption at Rest

Protect sensitive persisted data while the app in inactive.  

## Overview

Encryption at Rest (EAR) is a feature to protect sensitive data stored on the device while the app is "at rest", that is, when the app is not actively running. Most, if not all of the sensitive data is stored in Core Data. Since Core Data does not provide encryption at rest functionality, we must implement this functionality ourselves.

By definition, data that is encrypted at rest is persisted in encrypted form and, when it is decrypted, exists only in memory. To achieve this, the data needs to be encrypted when it is stored in the database and decrypted when it is retrieved from the database.

![Persisted data is encrypted, in-memory data is decrypted](encryption-at-rest)

### Encryption keys

When encryption at rest is enabled, several keys are generated: the primary keys, the secondary keys, and database key.

#### Primary keys

The primary keys are a public private key pair generated within a highly secure vault called the Secure Enclave, located in a separate security chip on the device. The public key is used for encryption and is easily accessible, whereas the private key is used for decryption and can only be accessed once the user has confirmed their identity via biometric authentication. This ensures the correct user is actively present.

#### Secondary keys

The secondary keys are the same as the primary keys, with the one difference that the private key does not require user presence, but only that the device has been unlocked once after boot. This means that the key is also accessible without the user being present, such as when the app is operating in the background.

#### Database key

The database key is some randomly generated data that is stored in the keychain as a generic password. The database key is itself encrypted at rest: it is encrpyted by the primary public key when stored in the keychain, and decrypted by the primary private key when retrieved from the keychain. This means that the database key is only useable after successful biometric authentication.

### What is data encrypted?

All data this is deemed sensitive is encrypted at rest. This includes all messages sent and received and all stored update event data (which may contain user data) that is received from the backend and is awaiting processing.

> Important: If the keys are lost, the data can not be recovered.

Messages (specifically the serialized protobuf data) are encrypted with the **database key** prior to being stored in the message database. The same key is used to decrypt the messages after it has been retrieved from the database.

Stored update events (specifically the event payloads) are encrypted using one of the public keys prior to being inserted in the event database. The reason why it is not encrypted with the database key is because the database key is only accessible when the app is in the foreground and the user is present. This would prevent update events received in the background from being encrypted. The public key however is always accessible. 

The stored update events are decrypted with the associated private key. If this is the primary key, then the event can only be decrypted (and subsequently processed) when the app is in the foreground with user presence. If it is the secondary key, the event can be decrypted and processed without user presence in the background.

For this reason, only call events are encrypted and decrypted using the secondary keys, since these events need to be processed while the app is operating in the background during CallKit calls. 

Key | Location | Accessible | Purpose                          
--- | -------- | ------ | ---------------------- 
Primary public | Secure Enclave | Always | Encrypt all stored update events (except call events) and the database key.
Primary secondary | Secure Enclave | User presence | Decrypt all stored update events (except call events) and the database key.
Secondary public | Secure Enclave | Always | Encrypt call events only.
Secondary private | Secure Enclave | After first unlock | Decrypt call events only.
Database | Keychain | User presence | Encrypt and decrypt all messages.

### User flow

To illustrate how all these pieces work together, consider a user who wishes to view a message they have received while encryption at rest is enabled:

1. First, the user opens the app.
2. The user is prompted to verify their identity via biometric authentication.
3. If successful, the app uses the authentication result to fetch the private keys from the Secure Enclave (via the Keychain).
4. The app also fetches the encrypted database key from Keychain.
5. The database key is decrypted and stored in memory. At this point, the database is considered unlocked.
6. A new message is received, then encrypted with the database key, then stored in the database.
7. The user wishes to view the message in the UI.
8. The encrypted message is retrieved from the database, decrypted with the database key, then presented to the user.
9. The user closes the app.
10. The database key is discared, the database is considered locked.

![Basic flow describing user unlocking database to access messages](encryption-at-rest-in-action)

### Data migrations

#### When enabling / disabling encryption at rest

When encryption at rest is turned on a migration is needed to bring the existing database into the correct state. Once the encryption keys have been generated, we then proceed to encrypt all messages in the database with the database key. Similarly, when encryption at rest is turned off, we must decrypt all messages with the database key before the encryption keys are destroyed, otherwise the messages will no longer be accessible.

#### When exporting / restoring a database

Since the primary and secondary keys are protected by the Secure Enclave and can never leave it, we do not include any encryption keys in database backups. Therefore, while encryption at rest is enabled, all messages must be decrypted before exporting a backup of the database. Similiarly, when importing a database backup, all messages must be encrypted restoring the database.   
