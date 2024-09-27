//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - EnvironmentType

public enum EnvironmentType: Equatable {
    case production
    case staging
    case qaDemo
    case qaDemo2
    case anta
    case bella
    case chala
    case diya
    case elna
    case foma
    case custom(url: URL)

    // MARK: Lifecycle

    public init(stringValue: String) {
        switch stringValue {
        case EnvironmentType.staging.stringValue:
            self = .staging

        case EnvironmentType.qaDemo.stringValue:
            self = .qaDemo

        case EnvironmentType.qaDemo2.stringValue:
            self = .qaDemo2

        case EnvironmentType.anta.stringValue:
            self = .anta

        case EnvironmentType.bella.stringValue:
            self = .bella

        case EnvironmentType.chala.stringValue:
            self = .chala

        case EnvironmentType.diya.stringValue:
            self = .diya

        case EnvironmentType.elna.stringValue:
            self = .elna

        case EnvironmentType.foma.stringValue:
            self = .foma

        case let value where value.hasPrefix("custom-"):
            let urlString = value.dropFirst("custom-".count)
            if let url = URL(string: String(urlString)) {
                self = .custom(url: url)
            } else {
                self = .production
            }

        default:
            self = .production
        }
    }

    // MARK: Internal

    var stringValue: String {
        switch self {
        case .production:
            "production"
        case .staging:
            "staging"
        case .qaDemo:
            "qa-demo"
        case .qaDemo2:
            "qa-demo-2"
        case .anta:
            "anta"
        case .bella:
            "bella"
        case .chala:
            "chala"
        case .diya:
            "diya"
        case .elna:
            "elna"
        case .foma:
            "foma"
        case let .custom(url: url):
            "custom-\(url.absoluteString)"
        }
    }
}

extension EnvironmentType {
    static let defaultsKey = "ZMBackendEnvironmentType"

    public init(userDefaults: UserDefaults) {
        if let value = userDefaults.string(forKey: EnvironmentType.defaultsKey) {
            self.init(stringValue: value)
        } else {
            Logging.backendEnvironment
                .error("Could not load environment type from user defaults, falling back to production")
            self = .production
        }
    }

    public func save(in userDefaults: UserDefaults) {
        userDefaults.setValue(stringValue, forKey: EnvironmentType.defaultsKey)
    }
}

// MARK: - BackendEnvironment

public final class BackendEnvironment: NSObject {
    // MARK: Lifecycle

    init(
        title: String,
        environmentType: EnvironmentType,
        endpoints: BackendEndpointsProvider,
        proxySettings: ProxySettingsProvider?,
        certificateTrust: BackendTrustProvider
    ) {
        self.title = title
        self.type = environmentType
        self.endpoints = endpoints
        self.proxySettings = proxySettings
        self.certificateTrust = certificateTrust
    }

    convenience init?(environmentType: EnvironmentType, data: Data) {
        struct SerializedData: Decodable {
            let title: String
            let endpoints: BackendEndpoints
            let apiProxy: ProxySettings?
            let pinnedKeys: [TrustData]?
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let backendData = try decoder.decode(SerializedData.self, from: data)
            let pinnedKeys = backendData.pinnedKeys ?? []
            let certificateTrust = ServerCertificateTrust(trustData: pinnedKeys)
            self.init(
                title: backendData.title,
                environmentType: environmentType,
                endpoints: backendData.endpoints,
                proxySettings: backendData.apiProxy,
                certificateTrust: certificateTrust
            )
        } catch {
            Logging.backendEnvironment.error("Could not decode information from data: \(error)")
            return nil
        }
    }

    // MARK: Public

    public let title: String

    // MARK: Internal

    let endpoints: BackendEndpointsProvider
    let proxySettings: ProxySettingsProvider?
    let certificateTrust: BackendTrustProvider
    let type: EnvironmentType
}

// MARK: BackendEnvironmentProvider

extension BackendEnvironment: BackendEnvironmentProvider {
    public var environmentType: EnvironmentTypeProvider {
        EnvironmentTypeProvider(environmentType: type)
    }

    public var backendURL: URL {
        endpoints.backendURL
    }

    public var backendWSURL: URL {
        endpoints.backendWSURL
    }

    public var blackListURL: URL {
        endpoints.blackListURL
    }

    public var teamsURL: URL {
        endpoints.teamsURL
    }

    public var accountsURL: URL {
        endpoints.accountsURL
    }

    public var websiteURL: URL {
        endpoints.websiteURL
    }

    public var countlyURL: URL? {
        endpoints.countlyURL
    }

    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        certificateTrust.verifyServerTrust(trust: trust, host: host)
    }

    public var proxy: ProxySettingsProvider? {
        proxySettings
    }
}
