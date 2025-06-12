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
import WireAPI
import WireAuthenticationDomain

public extension NetworkService {

    static func make(
        backendConfig: BackendConfig,
        minTLSVersion: TLSVersion,
        proxyCredentials: ProxyCredentials? = nil
    ) throws(InitializationError) -> NetworkServiceRepository {
        var pinnedKeys = [PinnedKey]()

        do {
            for trustData in backendConfig.pinnedKeys ?? [] {
                pinnedKeys.append(try PinnedKey(trustData))
            }
        } catch {
            pinnedKeys = []
        }

        let networkService = NetworkService(
            baseURL: backendConfig.endpoints.backendURL,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: pinnedKeys,
                currentDateProvider: .system
            )
        )

        let proxySettings: WireAPI.ProxySettings?
        if let configProxySettings = backendConfig.proxySettings {
            if configProxySettings.needsAuthentication {
                guard let proxyCredentials else {
                    throw .proxyCredentialsRequired
                }
                proxySettings = .authenticated(
                    host: configProxySettings.host,
                    port: configProxySettings.port,
                    username: proxyCredentials.username,
                    password: proxyCredentials.password
                )
            } else {
                proxySettings = .unauthenticated(
                    host: configProxySettings.host,
                    port: configProxySettings.port
                )
            }
        } else {
            proxySettings = nil
        }

        let config = URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: proxySettings
        ).makeRESTAPISessionConfiguration()

        let session = URLSession(
            configuration: config,
            delegate: networkService,
            delegateQueue: nil
        )

        networkService.configure(with: session)
        return networkService
    }

    enum InitializationError: Error {

        case proxyCredentialsRequired

    }

}

extension NetworkService: NetworkServiceRepository { }


private extension PinnedKey {

    init(_ trustData: TrustData) throws {
        try self.init(
            key: trustData.certificateKey,
            hosts: trustData.hosts.map { host in
                switch host.rule {
                case .equals:
                    .equals(host.value)
                case .endsWith:
                    .endsWith(host.value)
                }
            }
        )
    }

}
