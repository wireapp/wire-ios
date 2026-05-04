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

public struct TrustData: Decodable {
    public struct Host: Decodable {
        public enum Rule: String, Decodable {
            case endsWith = "ends_with"
            case equals
        }

        public let rule: Rule
        public let value: String

        public init(
            rule: Rule,
            value: String
        ) {
            self.rule = rule
            self.value = value
        }
    }

    public let certificateKey: SecKey
    public let rawCertificateKey: Data
    public let hosts: [Host]

    enum CodingKeys: String, CodingKey {
        case certificateKey
        case hosts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawCertificateKey = try container.decode(Data.self, forKey: .certificateKey)
        let hosts = try container.decode([TrustData.Host].self, forKey: .hosts)

        do {
            try self.init(
                rawCertificateKey: rawCertificateKey,
                hosts: hosts
            )
        } catch Failure.invalidCertificateKeyData {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.certificateKey,
                in: container,
                debugDescription: "Error decoding certificate for pinned key"
            )
        } catch Failure.invalidCertificateKey {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.certificateKey,
                in: container,
                debugDescription: "Error extracting pinned key from certificate"
            )
        }
    }

    public init(
        certificateKey: SecKey,
        rawCertificateKey: Data,
        hosts: [Host]
    ) {
        self.certificateKey = certificateKey
        self.rawCertificateKey = rawCertificateKey
        self.hosts = hosts
    }

    public init(
        rawCertificateKey: Data,
        hosts: [Host]
    ) throws {
        guard let certificate = SecCertificateCreateWithData(nil, rawCertificateKey as CFData) else {
            throw Failure.invalidCertificateKeyData
        }

        guard let certificateKey = SecCertificateCopyKey(certificate) else {
            throw Failure.invalidCertificateKey
        }

        self.certificateKey = certificateKey
        self.rawCertificateKey = rawCertificateKey
        self.hosts = hosts
    }

    public enum Failure: Error {
        case invalidCertificateKeyData
        case invalidCertificateKey
    }

}

extension TrustData {
    func matches(host: String) -> Bool {
        let matchingHosts = hosts.filter { $0.matches(host: host) }
        return !matchingHosts.isEmpty
    }
}

extension TrustData.Host {
    func matches(host: String) -> Bool {
        switch rule {
        case .endsWith:
            host.hasSuffix(value)
        case .equals:
            host == value
        }
    }
}
