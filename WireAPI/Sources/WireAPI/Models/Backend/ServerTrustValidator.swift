//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

    enum Failure: Error, Equatable {
        case evaluatingServerTrustFailed
        case noPublicKeyOnServerTrust
        case noMatchingPublicKey
    }

    private let pinnedKeys: [PinnedKey]

    init(pinnedKeys: [PinnedKey]) {
        self.pinnedKeys = pinnedKeys
    }

    /// Verifies the server `trust` for the given `host`.
    ///
    /// - Parameter trust: The `SecTrust` of the server.
    /// - Parameter host: The host of the server.
    /// - Throws: An error if server certificate should not be trusted.
    /// - Note: If no pinned keys are found for the `host`, the server certificate is trusted.

    func validate(trust: SecTrust, host: String) async throws {
        let matchingKeys = pinnedKeys.filter { $0.matches(host: host) }.map(\.key)

        // If no keys are pinned for `host`, we trust the server certificate
        guard !matchingKeys.isEmpty else { return }

        try await Self.verifyServerCertificateTrusted(trust)

        let publicKey = try Self.publicKeyAssociatedWithServerTrust(trust)

        guard matchingKeys.contains(publicKey) else {
            throw Failure.noMatchingPublicKey
        }
    }

    // MARK: - Private

    private static func verifyServerCertificateTrusted(_ serverTrust: SecTrust) async throws {
        try await withCheckedThrowingContinuation { continuation in
            // `SecTrustEvaluateAsyncWithError` requires the completion queue to be the same as the queue on which it
            // is called.
            let queue = DispatchQueue.global()
            queue.async {
                SecTrustEvaluateAsyncWithError(serverTrust, queue) { _, success, error in
                    if success {
                        continuation.resume()
                    } else {
                        print("Server trust evaluation failed: \(String(describing: error))")
                        continuation.resume(throwing: Failure.evaluatingServerTrustFailed)
                    }
                }
            }
        }
    }

    /// Returns the public key of the leaf certificate associated with `serverTrust`.
    ///
    /// - Parameter serverTrust: SecTrust of server
    /// - Returns: public key from `serverTrust`

    private static func publicKeyAssociatedWithServerTrust(_ serverTrust: SecTrust) throws -> SecKey {
        let certificates = SecTrustCopyCertificateChain(serverTrust) ?? [] as CFArray
        let policy = SecPolicyCreateBasicX509()
        var secTrust: SecTrust?

        guard SecTrustCreateWithCertificates(certificates, policy, &secTrust) == noErr,
              let trust = secTrust,
              let result = SecTrustCopyKey(trust)
        else {
            throw Failure.noPublicKeyOnServerTrust
        }

        return result
    }

}
