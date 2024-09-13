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

extension ZMUserSession: AccessTokenRenewing {
    func renewAccessToken(with clientID: String) {
        transportSession.renewAccessToken(with: clientID)
    }

    func setAccessTokenRenewalObserver(_ observer: AccessTokenRenewalObserver) {
        accessTokenRenewalObserver = observer
    }

    func transportSessionAccessTokenDidFail(response: ZMTransportResponse) {
        WireLogger.authentication.error("access token renewal failed: response status: \(response.errorInfo)")

        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else { return }
            let selfUser = ZMUser.selfUser(in: managedObjectContext)
            let error = NSError.userSessionError(
                code: .accessTokenExpired,
                userInfo: selfUser.loginCredentials.dictionaryRepresentation
            )
            notifyAuthenticationInvalidated(error)
        }

        accessTokenRenewalObserver?.accessTokenRenewalDidFail()
        accessTokenRenewalObserver = nil
    }

    func transportSessionAccessTokenDidSucceed() {
        WireLogger.authentication.info("access token renewal did succeed")
        accessTokenRenewalObserver?.accessTokenRenewalDidSucceed()
        accessTokenRenewalObserver = nil
    }
}
