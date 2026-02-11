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

import Foundation
import WireLogging

protocol AccessTokenRenewing {
    func setAccessTokenRenewalObserver(_ observer: AccessTokenRenewalObserver)
    func renewAccessToken(with clientID: String)
}

extension ZMUserSession: AccessTokenRenewing {

    func renewAccessToken(with clientID: String) {
        WireLogger.session.debug("🎟️🔓 renewAccessToken clientID: \(clientID)")
        transportSession.renewAccessToken(with: clientID)
    }

    func transportSessionAccessTokenDidFail(response: ZMTransportResponse) {
        WireLogger.authentication.error("🎟️🔓 access token renewal failed: response status: \(response.errorInfo)")

        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else { return }
            let selfUser = ZMUser.selfUser(in: managedObjectContext)
            let error = NSError.userSessionError(
                code: .accessTokenExpired,
                userInfo: selfUser.loginCredentials.dictionaryRepresentation
            )
            notifyAuthenticationInvalidated(error)
        }
    }

    func transportSessionAccessTokenDidSucceed() {
        WireLogger.authentication.info("🎟️🔓 access token renewal did succeed")
    }
}
