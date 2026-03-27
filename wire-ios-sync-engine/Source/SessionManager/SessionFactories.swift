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

import avs
import WireDataModel
import WireDomain
import WireLogging
import WireNetwork

open class UnauthenticatedSessionFactory {

    var environment: BackendEnvironmentProvider
    var reachability: Reachability

    var readyForRequests: Bool = false
    let appVersion: String

    init(
        appVersion: String,
        environment: BackendEnvironmentProvider,
        proxyUsername: String?,
        proxyPassword: String?,
        reachability: Reachability
    ) {
        self.environment = environment
        self.proxyUsername = proxyUsername
        self.proxyPassword = proxyPassword
        self.reachability = reachability
        self.appVersion = appVersion
    }

    func session(
        delegate: UnauthenticatedSessionDelegate,
        authenticationStatusDelegate: ZMAuthenticationStatusDelegate
    ) -> UnauthenticatedSession {
        let transportSession = UnauthenticatedTransportSession(
            environment: environment,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword,
            reachability: reachability,
            applicationVersion: appVersion,
            readyForRequests: readyForRequests
        )

        return UnauthenticatedSession(
            transportSession: transportSession,
            reachability: reachability,
            delegate: delegate,
            authenticationStatusDelegate: authenticationStatusDelegate,
            userPropertyValidator: UserPropertyValidator()
        )
    }

    public func updateProxy(username: String?, password: String?) {
        proxyUsername = username
        proxyPassword = password
    }

    // MARK: - Private

    private var proxyUsername: String?
    private var proxyPassword: String?
}
