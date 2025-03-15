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
import WireAuthenticationAPI

extension NetworkService {

    static func make(
        backendEnvironment: BackendEnvironment,
        minTLSVersion: TLSVersion
    ) -> NetworkService {
        let service = NetworkService(
            baseURL: backendEnvironment.url,
            serverTrustValidator: ServerTrustValidator(pinnedKeys: backendEnvironment.pinnedKeys)
        )

        let config = URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: backendEnvironment.proxySettings
        ).makeRESTAPISessionConfiguration()

        let session = URLSession(configuration: config, delegate: service, delegateQueue: nil)
        service.configure(with: session)

        return service
    }

}

final class ConfigurableNetworkService: NetworkServiceProtocol {

    private let minTLSVersion: TLSVersion
    private var service: (environment: BackendEnvironment, service: NetworkService)?

    init(minTLSVersion: TLSVersion) {
        self.minTLSVersion = minTLSVersion
    }

    func configure(with config: ResolvedBackendConfig) {
        let backgroundEnvironment = BackendEnvironment(
            url: config.endpoints.backendURL,
            webSocketURL: config.endpoints.backendWSURL,
            pinnedKeys: [], // FIXME: Map pinned keys
            proxySettings: config.proxySettings.map { settings in
                switch settings {
                case .unauthenticated(host: let host, port: let port):
                    .unauthenticated(host: host, port: port)
                case .authenticated(host: let host, port: let port, username: let username, password: let password):
                    .authenticated(host: host, port: port, username: username, password: password)
                }
            }
        )

        // Avoid recreating an existing NetworkService
        guard service?.environment != backgroundEnvironment else { return }

        service = (
            environment: backgroundEnvironment,
            service: NetworkService.make(backendEnvironment: backgroundEnvironment, minTLSVersion: minTLSVersion)
        )
    }

    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        assert(service != nil, "Service not configured")

        guard let service = service else {
            fatalError("Service not configured") // FIXME: Throw instead of fatal error
        }

        return try await service.service.executeRequest(request)
    }
}
