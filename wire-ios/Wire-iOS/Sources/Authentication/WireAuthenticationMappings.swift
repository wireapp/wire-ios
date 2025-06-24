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
import WireAuthentication
import WireFoundation
import WireNetwork
import WireNetworkInterface
import WireTransport

extension WireTransport.BackendEnvironment {

    convenience init(_ backendEnvironment: BackendEnvironment2) {
        let endpoints = BackendEndpoints(
            backendURL: backendEnvironment.config.endpoints.restAPIURL,
            backendWSURL: backendEnvironment.config.endpoints.websocketURL,
            blackListURL: backendEnvironment.config.endpoints.blacklistURL,
            teamsURL: backendEnvironment.config.endpoints.teamsURL,
            accountsURL: backendEnvironment.config.endpoints.accountsURL,
            websiteURL: backendEnvironment.config.endpoints.websiteURL,
            countlyURL: backendEnvironment.config.endpoints.countlyURL
        )
        let proxySettings = backendEnvironment.config.proxyConfig.map {
            WireTransport.ProxySettings(
                host: $0.host,
                port: $0.port,
                needsAuthentication: $0.needsAuthentication
            )
        }

        var trustData = [WireTransport.TrustData]()
        trustData = backendEnvironment.config.pinnedKeys.compactMap {
            try? TrustData(
                rawCertificateKey: $0.rawKey,
                hosts: $0.hosts.map { host in
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

        let certificateTrust = ServerCertificateTrust(trustData: trustData, currentDateProvider: .system)

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

extension WireTransport.APIVersion {

    init(_ apiVersion: WireNetworkInterface.APIVersion) {
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
