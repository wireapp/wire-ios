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
import WireLogging

package final class NetworkStack {

    enum Failure: Error {

        case proxyCredentialsRequired

    }

    package let backendInfo: BackendInfo
    package let minTLSVersion: TLSVersion
    package let preferredAPIVersion: APIVersion?

    private var backendMetadata: WireAuthenticationAPI.BackendMetadata?
    private var state: NetworkState
    private var proxyCredentials: ProxyCredentials?

    package init(
        backendInfo: BackendInfo,
        minTLSVersion: TLSVersion,
        preferredAPIVersion: APIVersion?
    ) {
        self.backendInfo = backendInfo
        self.minTLSVersion = minTLSVersion
        self.preferredAPIVersion = preferredAPIVersion

        do {
            self.state = .ready(try NetworkService.make(
                backendConfig: backendInfo.backendConfig,
                minTLSVersion: minTLSVersion,
                proxyCredentials: nil
            ))
        } catch .proxyCredentialsRequired {
            self.state = .awaitingProxyCredentials
        } catch {
            // Xcode warns that this case will never be executed, but if
            // we take it away, it complains that not all errors are handled.
        }
    }

    // MARK: - Methods

    package func setProxyCredentials(_ proxyCredentials: ProxyCredentials) throws {
        self.proxyCredentials = proxyCredentials
        state = .ready(try NetworkService.make(
            backendConfig: backendInfo.backendConfig,
            minTLSVersion: minTLSVersion,
            proxyCredentials: proxyCredentials
        ))
    }

    package func makeBackendEnvironment() async throws -> WireAuthenticationBackendEnvironment {
        let backendMetadata = try await resolvedBackendMetadata()

        var resolvedProxySettings: ResolvedProxySettings?
        if let proxySettings = backendInfo.backendConfig.proxySettings {
            if proxySettings.needsAuthentication {
                guard let proxyCredentials else {
                    throw Failure.proxyCredentialsRequired
                }

                resolvedProxySettings = .authenticated(
                    host: proxySettings.host,
                    port: proxySettings.port,
                    username: proxyCredentials.username,
                    password: proxyCredentials.password
                )
            } else {
                resolvedProxySettings = .unauthenticated(
                    host: proxySettings.host,
                    port: proxySettings.port
                )
            }
        }

        return WireAuthenticationBackendEnvironment(
            environmentType: backendInfo.environmentType,
            config: backendInfo.backendConfig,
            metadata: backendMetadata,
            proxySettings: resolvedProxySettings
        )
    }

    package func makeAuthenticationAPI() async throws -> some AuthenticationAPI {
        let apiVersion = try await resolvedAPIVersion()
        return AuthenticationAPIBuilder(networkService: try networkService).makeAPI(for: apiVersion)
    }

    // MARK: - Private

    private func resolvedAPIVersion() async throws -> APIVersion {
        let backendMetadata = try await resolvedBackendMetadata()
        return APIVersion(backendMetadata.apiVersion)
    }

    private func resolvedBackendMetadata() async throws -> WireAuthenticationAPI.BackendMetadata {
        if let backendMetadata {
            return backendMetadata
        }

        let api = BackendMetadataAPIBuilder(networkService: try networkService).makeAPI()

        let useCase = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: preferredAPIVersion
        )

        let backendMetadata = try await useCase.invoke()
        self.backendMetadata = backendMetadata
        return backendMetadata
    }

    private var networkService: NetworkService {
        get throws {
            switch state {
            case .awaitingProxyCredentials:
                throw Failure.proxyCredentialsRequired
            case let .ready(networkService):
                networkService
            }
        }
    }

}

private enum NetworkState {

    case awaitingProxyCredentials
    case ready(NetworkService)

}

private extension BackendConfig {

    var requiresProxyCredentials: Bool {
        proxySettings?.needsAuthentication == true
    }

}

private extension APIVersion {

    init(_ apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion) {
        switch apiVersion {
        case .v0:
            self = .v0
        case .v1:
            self = .v1
        case .v2:
            self = .v2
        case .v3:
            self = .v3
        case .v4:
            self = .v4
        case .v5:
            self = .v5
        case .v6:
            self = .v6
        case .v7:
            self = .v7
        case .v8:
            self = .v8
        }
    }

}

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

private extension NetworkService {

    static func make(
        backendConfig: BackendConfig,
        minTLSVersion: TLSVersion,
        proxyCredentials: ProxyCredentials? = nil
    ) throws(InitializationError) -> NetworkService {
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
            serverTrustValidator: ServerTrustValidator(pinnedKeys: pinnedKeys)
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
