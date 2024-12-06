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

import WireTestingPackage
import XCTest

@testable import WireAPI

final class ServerTrustValidatorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidate_whenNoMatchingHosts() async throws {
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(key: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ]
        )

        try await sut.validate(trust: .other, host: "example.com")
    }

    func testValidate_whenInvalidServerTrust() async throws {
        // GIVEN
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(key: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ]
        )

        // WHEN, THEN
        await XCTAssertThrowsErrorAsync(
            ServerTrustValidator.Failure.evaluatingServerTrustFailed,
            when: { try await sut.validate(trust: .invalid, host: "prod-nginz-https.wire.com") }
        )
    }

    func testValidate_whenNoMatchingPublicKey() async throws {
        // GIVEN
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(key: PublicKeys.wire, hosts: [.equals("example.com")])
            ]
        )

        // WHEN, THEN
        await XCTAssertThrowsErrorAsync(
            ServerTrustValidator.Failure.noMatchingPublicKey,
            when: { try await sut.validate(trust: .other, host: "example.com") }
        )
    }

}

// MARK: - Test Data

private extension SecTrust {

    enum Failure: Error {
        case failedToCreateCertificate
        case failedToCreateTrust
    }

    static var wire: SecTrust {
        get throws { try make(data: Certificates.load().wire) }
    }

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
