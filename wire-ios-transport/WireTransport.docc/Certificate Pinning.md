# Certificate pinning

Verify the identity of backend servers by checking certificates.

## Overview

Certificate pinning is a process to ensure a client is communicating with a trusted server. To achieve this, the client compares a certificate obtained from a server with a known certificate that it has stored locally. If the certificates match then the server is considered trustworthy.


Here, we only verify the public key of the certificate that way when server changes its certificate (and keeping the same public key), we won't have to update all clients. We also check the certificate downloaded from the server is not expired.

> Note: we only check the certificate of servers listed in the configuration of the ``BackendEnvironment`` stored `Backend.bundle`.


### About testing

The test `testPinnedHostsWithValidCertificateIsTrustedAreTrusted` located [here](https://github.com/wireapp/wire-ios/blob/ed7f01240d44dedb22f5f123d549cca69598002c/wire-ios-transport/Tests/Source/URLSession/ServerCertificateTrustTests.swift#L141) **will fail when the certificate of the server expires** because we check if the certificate is valid (not expired). 

This fails because the test uses a local copy. To solve this, one just needs to run the following command: 

```
openssl s_client -showcerts -servername prod-nginz-https.wire.com -connect prod-nginz-https.wire.com:443
```
