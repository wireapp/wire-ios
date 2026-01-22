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
import WireNetwork
import WireTransport

public extension BackendEnvironment2 {

    init(_ legacyEnvironment: WireTransport.BackendEnvironment) {
        let environmentType: EnvironmentType = switch legacyEnvironment.environmentType.value {
        case .default:
            .default
        case .staging:
            .staging
        case .anta:
            .anta
        case .bella:
            .bella
        case .chala:
            .chala
        case .diya:
            .diya
        case .elna:
            .elna
        case .foma:
            .foma
        case let .custom(url):
            .custom(url: url)
        }

        let endpoints = Endpoints(
            restAPIURL: legacyEnvironment.backendURL,
            websocketURL: legacyEnvironment.backendWSURL,
            blacklistURL: legacyEnvironment.blackListURL,
            teamsURL: legacyEnvironment.teamsURL,
            accountsURL: legacyEnvironment.accountsURL,
            websiteURL: legacyEnvironment.websiteURL,
            countlyURL: legacyEnvironment.countlyURL
        )

        let pinnedKeys: [PinnedKey] = legacyEnvironment.trustData.map {
            PinnedKey(
                key: $0.certificateKey,
                rawKey: $0.rawCertificateKey,
                hosts: $0.hosts.map { host in
                    switch host.rule {
                    case .endsWith:
                        .endsWith(host.value)
                    case .equals:
                        .equals(host.value)
                    }
                }
            )
        }

        let proxyConfig = legacyEnvironment.proxy.map {
            ProxyConfig(
                host: $0.host,
                port: $0.port,
                needsAuthentication: $0.needsAuthentication
            )
        }

        let config = Config(
            endpoints: endpoints,
            pinnedKeys: pinnedKeys,
            proxyConfig: proxyConfig
        )

        self.init(
            title: legacyEnvironment.title,
            environmentType: environmentType,
            config: config
        )
    }

}

public extension WireNetwork.APIVersion {

    init(_ legacyVersion: WireTransport.APIVersion) {
        switch legacyVersion {
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
        case .v9:
            self = .v9
        case .v10:
            self = .v10
        case .v11:
            self = .v11
        case .v12:
            self = .v12
        case .v13:
            self = .v13
        case .v14:
            self = .v14
        case .v15:
            self = .v15
        }
    }

}

public extension WireTransport.BackendEnvironment {

    convenience init(_ backendEnvironment: BackendEnvironment2) {
        let trustData: [TrustData] = backendEnvironment.config.pinnedKeys.map { pinnedKey in
            TrustData(
                certificateKey: pinnedKey.key,
                rawCertificateKey: pinnedKey.rawKey,
                hosts: pinnedKey.hosts.map { host in
                    switch host {
                    case let .endsWith(value):
                        TrustData.Host(
                            rule: .endsWith,
                            value: value
                        )
                    case let .equals(value):
                        TrustData.Host(
                            rule: .equals,
                            value: value
                        )
                    }
                }
            )
        }

        let environmentType: EnvironmentType = switch backendEnvironment.environmentType {
        case .default:
            .default
        case .staging:
            .staging
        case .anta:
            .anta
        case .bella:
            .bella
        case .chala:
            .chala
        case .diya:
            .diya
        case .elna:
            .elna
        case .foma:
            .foma
        case let .custom(url):
            .custom(url: url)
        }

        let endpoints = BackendEndpoints(
            backendURL: backendEnvironment.config.endpoints.restAPIURL,
            backendWSURL: backendEnvironment.config.endpoints.websocketURL,
            blackListURL: backendEnvironment.config.endpoints.blacklistURL,
            teamsURL: backendEnvironment.config.endpoints.teamsURL,
            accountsURL: backendEnvironment.config.endpoints.accountsURL,
            websiteURL: backendEnvironment.config.endpoints.websiteURL,
            countlyURL: backendEnvironment.config.endpoints.countlyURL
        )

        var proxySettings: WireTransport.ProxySettings?
        if let proxyConfig = backendEnvironment.config.proxyConfig {
            proxySettings = WireTransport.ProxySettings(
                host: proxyConfig.host,
                port: proxyConfig.port,
                needsAuthentication: proxyConfig.needsAuthentication
            )
        }

        let certificateTrust = ServerCertificateTrust(
            trustData: trustData,
            currentDateProvider: .system
        )

        self.init(
            title: backendEnvironment.title,
            trustData: trustData,
            environmentType: environmentType,
            endpoints: endpoints,
            proxySettings: proxySettings,
            certificateTrust: certificateTrust
        )
    }

}
