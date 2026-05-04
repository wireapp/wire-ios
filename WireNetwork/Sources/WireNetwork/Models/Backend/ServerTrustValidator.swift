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

public import WireFoundation

import Foundation
@preconcurrency import Security

public struct ServerTrustValidator: Sendable {

    enum Failure: Error, Equatable {
        case settingVerifyDate(_ status: OSStatus)
        case evaluatingServerTrustFailed(_ status: OSStatus)
        case unexpected(String)
        case noPublicKeyOnServerTrust
        case noMatchingPublicKey
    }

    private let pinnedKeys: [PinnedKey]
    private let currentDateProvider: any CurrentDateProviding

    public init(
        pinnedKeys: [PinnedKey],
        currentDateProvider: any CurrentDateProviding
    ) {
        self.pinnedKeys = pinnedKeys
        self.currentDateProvider = currentDateProvider
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

        try await Self.verifyServerCertificateTrusted(trust, currentDateProvider.now)

        let publicKey = try Self.publicKeyAssociatedWithServerTrust(trust)

        guard matchingKeys.contains(publicKey) else {
            throw Failure.noMatchingPublicKey
        }
    }

    // MARK: - Private

    private static func verifyServerCertificateTrusted(
        _ serverTrust: SecTrust,
        _ verifyDate: Date
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in

            // `SecTrustEvaluateAsyncWithError` requires the completion queue to be the same as the queue on which it
            // is called.
            let queue = DispatchQueue.global()
            queue.async {

                var status = SecTrustSetVerifyDate(serverTrust, verifyDate as CFDate)
                guard status == errSecSuccess else {
                    return continuation.resume(throwing: Failure.settingVerifyDate(status))
                }

                status = SecTrustEvaluateAsyncWithError(serverTrust, queue) { _, success, error in
                    if success {
                        return continuation.resume()
                    }
                    guard
                        let error = error as (any Error)? as NSError?,
                        error.domain == NSOSStatusErrorDomain,
                        let status = OSStatus(exactly: error.code)
                    else {
                        return continuation.resume(throwing: Failure.unexpected(String(reflecting: error)))
                    }
                    continuation.resume(throwing: Failure.evaluatingServerTrustFailed(status))
                }
                // The method calls the closure exactly once if the method
                // returns errSecSuccess, and not at all otherwise.
                // https://developer.apple.com/documentation/security/sectrustevaluateasyncwitherror(_:_:_:)#parameters
                if status != errSecSuccess {
                    continuation.resume(throwing: Failure.evaluatingServerTrustFailed(status))
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
