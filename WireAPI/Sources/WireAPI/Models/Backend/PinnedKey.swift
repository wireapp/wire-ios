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
@preconcurrency import Security

/// Associates a list of `hosts` with a public `key`.

public struct PinnedKey: Sendable {

    public enum Failure: Error {
        case invalidKeyData
    }

    public enum Host: Sendable {
        case endsWith(String)
        case equals(String)
    }

    let key: SecKey
    let hosts: [Host]

    public init(key: SecKey, hosts: [Host]) {
        self.key = key
        self.hosts = hosts
    }

    public init(key: Data, hosts: [Host]) throws(Failure) {
        self.key = try Self.key(for: key)
        self.hosts = hosts
    }

    /// Returns `true` if `host` matches any of the `hosts` in `self`.

    func matches(host: String) -> Bool {
        hosts.contains {
            switch $0 {
            case let .endsWith(suffix):
                host.hasSuffix(suffix)
            case let .equals(value):
                host == value
            }
        }
    }

    // MARK: - Private

    private static func key(for data: Data) throws(Failure) -> SecKey {
        guard
            let certificate = SecCertificateCreateWithData(nil, data as CFData),
            let publicKey = SecCertificateCopyKey(certificate)
        else {
            throw Failure.invalidKeyData
        }

        return publicKey
    }

}
