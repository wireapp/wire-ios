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

extension NetworkService {

    static func makeServices(
        backendConfig: BackendEnvironment2.Config,
        minTLSVersion: TLSVersion,
        proxyCredentials: ProxyCredentials? = nil
    ) throws(InitializationError) -> (
        rest: NetworkService,
        webSocket: NetworkService,
        blacklist: NetworkService
    ) {
        let proxySettings: ProxySettings?
        if let proxyConfig = backendConfig.proxyConfig {
            if proxyConfig.needsAuthentication {
                guard let proxyCredentials else {
                    throw .proxyCredentialsRequired
                }
                proxySettings = .authenticated(
                    host: proxyConfig.host,
                    port: proxyConfig.port,
                    username: proxyCredentials.username,
                    password: proxyCredentials.password
                )
            } else {
                proxySettings = .unauthenticated(
                    host: proxyConfig.host,
                    port: proxyConfig.port
                )
            }
        } else {
            proxySettings = nil
        }

        let configFactory = URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: proxySettings
        )

        let restService = NetworkService(
            baseURL: backendConfig.endpoints.restAPIURL,
            urlSessionConfiguration: configFactory.makeRESTAPISessionConfiguration(),
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendConfig.pinnedKeys,
                currentDateProvider: .system
            )
        )

        let webSocketService = NetworkService(
            baseURL: backendConfig.endpoints.websocketURL,
            urlSessionConfiguration: configFactory.makeWebSocketSessionConfiguration(),
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendConfig.pinnedKeys,
                currentDateProvider: .system
            )
        )

        let blacklistService = NetworkService(
            baseURL: backendConfig.endpoints.blacklistURL,
            urlSessionConfiguration: configFactory.makeBlacklistSessionConfiguration(),
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendConfig.pinnedKeys,
                currentDateProvider: .system
            )
        )

        return (
            rest: restService,
            webSocket: webSocketService,
            blacklist: blacklistService
        )
    }

    enum InitializationError: Error {

        case proxyCredentialsRequired

    }

}
