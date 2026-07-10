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

extension SecTrust {

    enum Failure: Error {
        case failedToCreateCertificate
        case failedToCreateTrust
    }

    static var wire: SecTrust {
        get throws { try make(data: Certificates.load().wire) }
    }

    /// This is the trust certificate from `google.com`. It will likely become invalid in the future and will need to be
    /// updated. To do this run the following from the command line:
    /// ```
    /// openssl s_client -connect google.com:443 -showcerts
    /// ```
    /// Then copy each certificate into the `other` section of `certificates.json` file of `WireNetwork`. This requires
    /// a
    /// bit of text wrangling such as removing line breaks etc.

    static var other: SecTrust {
        get throws { try make(data: Certificates.load().other) }
    }

    static var invalid: SecTrust {
        get throws { try make(data: Certificates.load().invalid) }
    }

    static func make(data: [Data]) throws -> SecTrust {
        let policy = SecPolicyCreateBasicX509()

        let certificates: [SecCertificate] = try data.compactMap {
            guard let cert = SecCertificateCreateWithData(nil, $0 as CFData) else {
                throw Failure.failedToCreateCertificate
            }
            return cert
        }
        var trust: SecTrust?
        guard SecTrustCreateWithCertificates(certificates as CFTypeRef, policy, &trust) == 0, let result = trust else {
            throw Failure.failedToCreateTrust
        }

        return result
    }

}

private struct Certificates: Decodable {

    let wire: [Data]
    let other: [Data]
    let invalid: [Data]

    static func load() throws -> Certificates {
        try Certificates.loadJSON(fileName: "certificates")
    }

}
