# ``WireDataModel/EARService``

## Topics

### Enable / disable encryption at rest

- ``isEAREnabled``
- ``enableEncryptionAtRest(context:skipMigration:)``
- ``disableEncryptionAtRest(context:skipMigration:)``

### Accessing keys

- ``fetchPublicKeys()``
- ``fetchPrivateKeys(includingPrimary:)``

### Lock / unlock the database

- ``lockDatabase()``
- ``unlockDatabase()``
