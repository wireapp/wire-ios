# Certificate pinning

Verify the identity of backend servers by checking certificates.

## Overview

Certificate pinning is a process to ensure a client is communicating with a trusted server. To achieve this, the client compares a certificate obtained from a server with a known certificate that it has stored locally. If the certificates match then the server is considered trustworthy.


One approach of certificate pinning involves comparing the entire certificate. The downside to this is that when the server eventually updates their certificate, then also the client must update its local certificate to continue to trust that server. This, in effect, means that older clients will no longer trust the server.

To avoid this issue, Wire employs a second approach, namely to verify only the public key of the certificate. In this way, if the server renews its certificate with the same public-private key pair, then all existing clients that have the same public key will continue to trust the server, even with new certificates. Specifically, a server is considered trusted when its certificate is not expired and its public key matches the known and trusted public key.

> Note: we only check the certificate of servers listed in the configuration of the ``BackendEnvironment`` stored `Backend.bundle`.


### About testing

The test `testPinnedHostsWithValidCertificateIsTrustedAreTrusted` located [here](https://github.com/wireapp/wire-ios/blob/ed7f01240d44dedb22f5f123d549cca69598002c/wire-ios-transport/Tests/Source/URLSession/ServerCertificateTrustTests.swift#L141) **will fail when the certificate of the server expires** because we check if the certificate is valid (not expired). 

This fails because the test uses a local copy. To solve this, one just needs to run the following command: 

```
openssl s_client -showcerts -servername prod-nginz-https.wire.com -connect prod-nginz-https.wire.com:443
```
