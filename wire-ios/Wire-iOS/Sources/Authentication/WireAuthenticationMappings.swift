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
import WireTransport

extension WireTransport.APIVersion {

    init(_ apiVersion: WireAuthentication.BackendMetadata.APIVersion) {
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

extension WireAuthentication.BackendConfig {

    init(_ backendEnvironment: WireTransport.BackendEnvironment) {
        let endpoints = Endpoints(
            backendURL: backendEnvironment.backendURL,
            backendWSURL: backendEnvironment.backendWSURL,
            blackListURL: backendEnvironment.blackListURL,
            teamsURL: backendEnvironment.teamsURL,
            accountsURL: backendEnvironment.accountsURL,
            websiteURL: backendEnvironment.websiteURL
        )

        let proxySettings = backendEnvironment.proxy.map { proxy in
            ProxySettings(
                host: proxy.host,
                port: proxy.port,
                needsAuthentication: proxy.needsAuthentication
            )
        }

        let pinnedKeys = backendEnvironment.trustData.map { trustData in
            TrustData(trustData)
        }

        self.init(
            title: backendEnvironment.title,
            endpoints: endpoints,
            proxySettings: proxySettings,
            pinnedKeys: pinnedKeys
        )
    }

}

extension WireAuthentication.TrustData {

    init(_ trustData: WireTransport.TrustData) {
        let hosts = trustData.hosts.map { host in
            let rule: Host.Rule = switch host.rule {
            case .endsWith:
                .endsWith
            case .equals:
                .equals
            }

            return Host(
                rule: rule,
                value: host.value
            )
        }

        self.init(
            certificateKey: trustData.rawCertificateKey,
            hosts: hosts
        )
    }

}
