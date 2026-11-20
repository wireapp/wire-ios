//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import WireCoreCrypto

extension CoreCryptoProtocol {

    /// Returns the credential to use for MLS operations with the given cipher suite.
    ///
    /// CoreCrypto 11 removed `e2eiIsEnabled`. E2EI counts as enabled when an X.509 credential exists for the
    /// cipher suite, in which case it is preferred; otherwise the basic credential is used.
    ///
    /// - Returns: the X.509 credential if one exists, otherwise the basic credential, or `nil` if neither exists.
    func preferredMLSCredential(cipherSuite: CipherSuite) async throws -> CredentialRef? {
        if let x509Credential = try await findCredentials(
            clientId: nil,
            publicKey: nil,
            cipherSuite: cipherSuite,
            credentialType: .x509,
            earliestValidity: nil
        ).first {
            return x509Credential
        }

        return try await findCredentials(
            clientId: nil,
            publicKey: nil,
            cipherSuite: cipherSuite,
            credentialType: .basic,
            earliestValidity: nil
        ).first
    }
}
