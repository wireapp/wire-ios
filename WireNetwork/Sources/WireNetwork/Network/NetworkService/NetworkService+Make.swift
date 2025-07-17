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

extension NetworkService {

    static func makeServices(
        backendConfig: BackendEnvironment2.Config,
        minTLSVersion: TLSVersion,
        proxyCredentials: ProxyCredentials? = nil
    ) throws(InitializationError) -> (
        rest: NetworkService,
        webSocket: NetworkService
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
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendConfig.pinnedKeys,
                currentDateProvider: .system
            )
        )

        let restSession = URLSession(
            configuration: configFactory.makeRESTAPISessionConfiguration(),
            delegate: restService,
            delegateQueue: nil
        )

        restService.configure(with: restSession)

        let webSocketService = NetworkService(
            baseURL: backendConfig.endpoints.websocketURL,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendConfig.pinnedKeys,
                currentDateProvider: .system
            )
        )

        let webSocketSession = URLSession(
            configuration: configFactory.makeWebSocketSessionConfiguration(),
            delegate: webSocketService,
            delegateQueue: nil
        )

        webSocketService.configure(with: webSocketSession)

        return (
            rest: restService,
            webSocket: webSocketService
        )
    }

    enum InitializationError: Error {

        case proxyCredentialsRequired

    }

}
