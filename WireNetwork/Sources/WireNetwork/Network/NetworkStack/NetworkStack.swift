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
import WireFoundation
import WireLogging
import WireNetworkInterface

// TODO: doc
public final class NetworkStack {

    public let backendEnvironment: BackendEnvironment2
    public private(set) var proxyCredentials: ProxyCredentials?

    let minTLSVersion: TLSVersion
    let preferredAPIVersion: APIVersion?

    private var state: NetworkState
    private var backendMetadata: ResolvedBackendMetadata?

    var networkServices: (rest: NetworkService, webSocket: NetworkService) {
        get throws {
            switch state {
            case .awaitingProxyCredentials:
                throw NetworkStackError.proxyCredentialsRequired
            case let .ready(rest, webSocket):
                (rest, webSocket)
            }
        }
    }

    public init(
        backendEnvironment: BackendEnvironment2,
        minTLSVersion: TLSVersion,
        preferredAPIVersion: APIVersion?,
        proxyCredentials: ProxyCredentials?
    ) {
        self.backendEnvironment = backendEnvironment
        self.minTLSVersion = minTLSVersion
        self.preferredAPIVersion = preferredAPIVersion

        do {
            let (restService, webSocketService) = try NetworkService.makeServices(
                backendConfig: backendEnvironment.config,
                minTLSVersion: minTLSVersion,
                proxyCredentials: proxyCredentials
            )
            self.state = .ready(
                rest: restService,
                webSocket: webSocketService
            )
        } catch .proxyCredentialsRequired {
            self.state = .awaitingProxyCredentials
        } catch {
            // Xcode warns that this case will never be executed, but if
            // we take it away, it complains that not all errors are handled.
        }
    }

    // MARK: - Methods

    public func setProxyCredentials(
        username: String,
        password: String
    ) throws {
        self.proxyCredentials = ProxyCredentials(
            username: username,
            password: password
        )

        let (restService, webSocketService) = try NetworkService.makeServices(
            backendConfig: backendEnvironment.config,
            minTLSVersion: minTLSVersion,
            proxyCredentials: proxyCredentials
        )

        self.state = .ready(
            rest: restService,
            webSocket: webSocketService
        )
    }

    public func resolvedAPIVersion() async throws -> APIVersion {
        let backendMetadata = try await resolvedBackendMetadata()
        return backendMetadata.apiVersion
    }

    public func resolvedBackendMetadata() async throws -> ResolvedBackendMetadata {
        if let backendMetadata {
            return backendMetadata
        }

        let api = BackendMetadataAPIBuilder(networkService: try networkServices.rest).makeAPI()

        let useCase = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: preferredAPIVersion
        )

        do {
            let backendMetadata = try await useCase.invoke()
            self.backendMetadata = backendMetadata
            return backendMetadata
        } catch ResolveBackendMetadataUseCaseFailure.backendAPIVersionObsolete {
            throw NetworkStackError.backendAPIVersionObsolete
        } catch ResolveBackendMetadataUseCaseFailure.clientVersionObsolete {
            throw NetworkStackError.clientVersionObsolete
        }
    }

}

private enum NetworkState {

    case awaitingProxyCredentials
    case ready(rest: NetworkService, webSocket: NetworkService)

}

// TODO: move to network service
private extension NetworkService {

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
