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

/// Provides a `MarketingConsentRepositoryProtocol` instance.

public protocol MarketingConsentRepositoryProvider {

    var marketingConsentRepository: MarketingConsentRepositoryProtocol { get }

}

/// Repository for interacting with marketing consent.
///
/// - note: This repository concerns a single user.

public protocol MarketingConsentRepositoryProtocol {

    /// Informs the repository that a marketing consent prompt has been shown.

    func didPromptForConsent() async

    /// Returns whether the user should be shown a prompt for marketing consent.

    func shouldPromptForConsent() async throws -> Bool

}

public actor MarketingConsentRepository: MarketingConsentRepositoryProtocol {

    private let transportSession: any TransportSessionType
    private let marketingConsentEnabled: Bool
    private let user: () -> ZMUser?
    private var consentAsked = false

    public init(transportSession: any TransportSessionType, marketingConsentEnabled: Bool, user: @escaping () -> ZMUser?) {
        self.transportSession = transportSession
        self.marketingConsentEnabled = marketingConsentEnabled
        self.user = user
    }

    public func didPromptForConsent() async {
        consentAsked = true
    }

    @MainActor
    public func shouldPromptForConsent() async throws -> Bool {
        guard let user = user() else {
            internalFailure("No user for fetching marketing consent")
            return false
        }

        guard marketingConsentEnabled, await !consentAsked else { return false }

        let asked: Bool = try await withCheckedThrowingContinuation { continuation in
            user.fetchConsent(for: .marketing, on: transportSession) { result in
                let consentAsked = result.map { $0 != nil }
                continuation.resume(with: consentAsked)
            }
        }

        // Don't override local value as backend might not know that consent has been asked locally
        if await !consentAsked && asked {
            await didPromptForConsent()
        }

        return await !consentAsked
    }

}
