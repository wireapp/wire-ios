//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

@testable import WireDataModel

public final class MockE2eIdentityProvider: E2eIdentityProviding {

    public let certificate: E2eIdentityCertificate = .mock()
    public let isE2EIdentityEnabled: Bool = false
    public let shouldCertificateBeUpdated = false

    public init() {
    }

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        certificate
    }

    public func isE2EIdentityEnabled() async throws -> Bool {
        return isE2EIdentityEnabled
    }

    public func fetchCertificates(clientIds: [Data]) async throws -> [WireDataModel.E2eIdentityCertificate] {
        []
    }

    public func fetchCertificates(userIds: [String]) async throws -> [String: [WireDataModel.E2eIdentityCertificate]] {
        [:]
    }

    public func shouldCertificateBeUpdated(for certificate: WireDataModel.E2eIdentityCertificate) -> Bool {
        shouldCertificateBeUpdated
    }

}
