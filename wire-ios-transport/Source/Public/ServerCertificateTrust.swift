//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Foundation
import WireFoundation

final class ServerCertificateTrust: NSObject, BackendTrustProvider {
    let trustData: [TrustData]

    init(trustData: [TrustData]) {
        self.trustData = trustData
    }

    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        guard let host else { return false }
        let pinnedKeys = trustData
            .filter { trustData in
                trustData.matches(host: host)
            }
            .map { trustData in
                trustData.certificateKey
            }

        return verifyServerTrustWithPinnedKeys(trust, pinnedKeys)
    }

    /// Returns the public key of the leaf certificate associated with the trust object
    /// 
    /// To dump certificate data, use
    ///     CFIndex const certCount = SecTrustGetCertificateCount(serverTrust);
    /// and
    ///     SecCertificateRef cert0 = SecTrustGetCertificateAtIndex(serverTrust, 0);
    ///     SecCertificateRef cert1 = SecTrustGetCertificateAtIndex(serverTrust, 1);
    /// etc. and then
    ///     SecCertificateCopyData(cert1)
    /// to dump the certificate data.
    ///
    ///
    /// Also
    ///     CFBridgingRelease(SecCertificateCopyValues(cert1, @[kSecOIDX509V1SubjectName], NULL))
    /// - Parameter serverTrust: SecTrust of server
    /// - Returns: public key form the trust
    private func publicKeyAssociatedWithServerTrust(_ serverTrust: SecTrust) -> SecKey? {
        let policy = SecPolicyCreateBasicX509()

        // leaf certificate
        let certificatesCArray: CFArray = SecTrustCopyCertificateChain(serverTrust) ?? [] as CFArray
        var secTrust: SecTrust?

        guard SecTrustCreateWithCertificates(certificatesCArray, policy, &secTrust) == noErr,
              let trust = secTrust else {
            return nil
        }

        return SecTrustCopyKey(trust)
    }

    private func verifyServerTrustWithPinnedKeys(_ serverTrust: SecTrust, _ pinnedKeys: [SecKey]) -> Bool {
        var someError: CFError?
        // serverTrust is the certificate coming from the backend server we make request to, so next line will
        // check that the certificate is not expired
        guard SecTrustEvaluateWithError(serverTrust, &someError) else {
            WireLogger.backend.error(someError?.localizedDescription ?? "verifyServerTrustWithPinnedKeys unknown error")
            return false
        }

        guard !pinnedKeys.isEmpty else {
            return true
        }
        // only checks the publicKey of certificate_key (located in Backend.bundle of the app) with the server public key
        guard let publicKey = publicKeyAssociatedWithServerTrust(serverTrust) else {
            return false
        }

        return pinnedKeys.contains(publicKey)
    }
}
