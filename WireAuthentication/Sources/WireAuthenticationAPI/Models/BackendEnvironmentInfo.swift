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

public struct BackendConfig: Decodable, Sendable, Hashable {

    /// The  name of the backend.

    public let title: String

    /// Backend URLs

    public let endpoints: Endpoints

    /// The proxy settings for the backend if any.

    public let proxySettings: ProxySettings?

    /// The pinned keys for the backend for use with certificate pinning.

    public let pinnedKeys: [TrustData]?

    public init(
        title: String,
        endpoints: Endpoints,
        proxySettings: ProxySettings?,
        pinnedKeys: [TrustData]?
    ) {
        self.title = title
        self.endpoints = endpoints
        self.proxySettings = proxySettings
        self.pinnedKeys = pinnedKeys
    }

}

public struct Endpoints: Decodable, Sendable, Hashable {

    public let backendURL: URL
    public let backendWSURL: URL
    public let blackListURL: URL
    public let teamsURL: URL
    public let accountsURL: URL
    public let websiteURL: URL

    public init(
        backendURL: URL,
        backendWSURL: URL,
        blackListURL: URL,
        teamsURL: URL,
        accountsURL: URL,
        websiteURL: URL
    ) {
        self.backendURL = backendURL
        self.backendWSURL = backendWSURL
        self.blackListURL = blackListURL
        self.teamsURL = teamsURL
        self.accountsURL = accountsURL
        self.websiteURL = websiteURL
    }
}

public struct TrustData: Decodable, Sendable, Hashable {

    public struct Host: Decodable, Sendable, Hashable {
        public enum Rule: String, Decodable, Sendable {
            case endsWith = "ends_with"
            case equals
        }

        public let rule: Rule
        public let value: String
    }

    public let certificateKey: SecKey
    public let hosts: [Host]

    enum CodingKeys: String, CodingKey {
        case certificateKey
        case hosts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let certificateKeyData = try container.decode(Data.self, forKey: .certificateKey)

        guard let certificate = SecCertificateCreateWithData(nil, certificateKeyData as CFData) else {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.certificateKey,
                in: container,
                debugDescription: "Error decoding certificate for pinned key"
            )
        }

        guard let certificateKey = SecCertificateCopyKey(certificate) else {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.certificateKey,
                in: container,
                debugDescription: "Error extracting pinned key from certificate"
            )
        }
        self.certificateKey = certificateKey
        self.hosts = try container.decode([TrustData.Host].self, forKey: .hosts)
    }

}

public struct ProxySettings: Decodable, Sendable, Hashable {

    public let host: String
    public let port: Int
    public let needsAuthentication: Bool

    init(
        host: String,
        port: Int,
        needsAuthentication: Bool = false
    ) {
        self.host = host
        self.port = port
        self.needsAuthentication = needsAuthentication

    }

}
