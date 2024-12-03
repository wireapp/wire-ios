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
@preconcurrency import Security

struct ServerTrustValidator: Sendable {

    enum Error: Swift.Error {
        case cannotLoadCertificate
        case cannotRetrievePublicKey
    }

    private let pinnedKeys: [PinnedKey]

    /// Verifies the server `trust` for the given `host`.
    ///
    /// - Parameter trust: The `SecTrust` of the server.
    /// - Parameter host: The host of the server.
    /// - Returns: `true` if the server trust is valid and its public key equals a pinned key with the same host,
    /// otherwise `false`.
    /// - Throws: If there is an error loading the pinned public keys.
    /// - Note: If no pinned keys are found for the `host`, the server certificate is trusted.

    func verifyServerTrust(trust: SecTrust, host: String) async throws -> Bool {
        let matches = pinnedKeys.filter { $0.matches(host: host) }

        // If no keys are pinned for `host`, we trust the server certificate
        guard !matches.isEmpty else { return true }

        guard await Self.verifyServerCertificateTrusted(trust) else { return false }

        guard let publicKey = Self.publicKeyAssociatedWithServerTrust(trust) else { return false }

        let publicKeys = try matches.map { try Self.certificateKey(for: $0) }
        return publicKeys.contains(publicKey)
    }

    // MARK: - Private

    private static func verifyServerCertificateTrusted(_ serverTrust: SecTrust) async -> Bool {
        await withCheckedContinuation { continuation in
            // `SecTrustEvaluateAsyncWithError` requires the completion queue to be the same as the queue on which it
            // is called.
            let queue = DispatchQueue.global()
            queue.async {
                SecTrustEvaluateAsyncWithError(serverTrust, queue) { _, success, error in
                    if success {
                        continuation.resume(returning: true)
                    } else {
                        print(error?.localizedDescription ?? "verifyServerTrust unknown error")
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    /// Returns the public key of the leaf certificate associated with `serverTrust`.
    ///
    /// - Parameter serverTrust: SecTrust of server
    /// - Returns: public key from `serverTrust`

    private static func publicKeyAssociatedWithServerTrust(_ serverTrust: SecTrust) -> SecKey? {
        let certificates = SecTrustCopyCertificateChain(serverTrust) ?? [] as CFArray
        let policy = SecPolicyCreateBasicX509()
        var secTrust: SecTrust?

        guard SecTrustCreateWithCertificates(certificates, policy, &secTrust) == noErr, let trust = secTrust else {
            return nil
        }

        return SecTrustCopyKey(trust)
    }

    private static func certificateKey(for value: PinnedKey) throws -> SecKey {
        guard let certificate = SecCertificateCreateWithData(nil, value.key as CFData) else {
            throw Error.cannotLoadCertificate
        }

        guard let publicKey = SecCertificateCopyKey(certificate) else {
            throw Error.cannotRetrievePublicKey
        }

        return publicKey
    }

}

// MARK: - Helpers

private extension PinnedKey {
    func matches(host: String) -> Bool {
        let matchingHosts = hosts.filter { $0.matches(host: host) }
        return !matchingHosts.isEmpty
    }
}

private extension PinnedKey.Host {
    func matches(host: String) -> Bool {
        switch rule {
        case .endsWith:
            host.hasSuffix(value)
        case .equals:
            host == value
        }
    }
}
