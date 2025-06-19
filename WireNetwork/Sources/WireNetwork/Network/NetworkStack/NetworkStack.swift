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

    var networkService: NetworkService {
        get throws {
            switch state {
            case .awaitingProxyCredentials:
                throw NetworkStackError.proxyCredentialsRequired
            case let .ready(networkService):
                networkService
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
            self.state = .ready(try NetworkService.make(
                backendConfig: backendEnvironment.config,
                minTLSVersion: minTLSVersion,
                proxyCredentials: proxyCredentials
            ))
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

        state = .ready(try NetworkService.make(
            backendConfig: backendEnvironment.config,
            minTLSVersion: minTLSVersion,
            proxyCredentials: proxyCredentials
        ))
    }

    public func resolvedAPIVersion() async throws -> APIVersion {
        let backendMetadata = try await resolvedBackendMetadata()
        return backendMetadata.apiVersion
    }

    public func resolvedBackendMetadata() async throws -> ResolvedBackendMetadata {
        if let backendMetadata {
            return backendMetadata
        }

        let api = BackendMetadataAPIBuilder(networkService: try networkService).makeAPI()

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
    case ready(NetworkService)

}

// TODO: move to network service
private extension NetworkService {

    static func make(
        backendConfig: BackendEnvironment2.Config,
        minTLSVersion: TLSVersion,
        proxyCredentials: ProxyCredentials? = nil
    ) throws(InitializationError) -> NetworkService {
        let networkService = NetworkService(
            baseURL: backendConfig.endpoints.restAPIURL,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendConfig.pinnedKeys,
                currentDateProvider: .system
            )
        )

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
