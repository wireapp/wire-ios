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

import AuthenticationServices
import Foundation

package protocol WebAuthenticatorProtocol {

    func authenticate(url: URL) async throws -> URL?

}

@MainActor
package final class WebAuthenticator: NSObject, WebAuthenticatorProtocol {

    private let ssoCallbackURLScheme: String

    package init(ssoCallbackURLScheme: String) {
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        super.init()
    }

    package func authenticate(url: URL) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: ssoCallbackURLScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: callbackURL)
                }
            }

            // Prevents cookie persistence.
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            session.start()
        }
    }

}

extension WebAuthenticator: ASWebAuthenticationPresentationContextProviding {

    package func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }

}
