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

import XCTest
@testable import WireDataModel
import WireCoreCrypto
import WireDataModelSupport

final class E2eIdentityProviderTests: XCTestCase {
    lazy var dateFormatter = DateFormatter()

    func testThatItsFalse_whenCertificateIsExpired() {
        let e2eIdentityProvider = E2eIdentityProvider(gracePeriod: 0,
                                                      coreCryptoProvider: MockCoreCryptoProviderProtocol(),
                                                      conversationId: Data())
        XCTAssertFalse(e2eIdentityProvider.shouldUpdateCertificate(for: .mockExpired))
    }

    func testThatItsFalse_whenCertificateIsRevoked() {
        let e2eIdentityProvider = E2eIdentityProvider(gracePeriod: 0,
                                                      coreCryptoProvider: MockCoreCryptoProviderProtocol(),
                                                      conversationId: Data())
        XCTAssertFalse(e2eIdentityProvider.shouldUpdateCertificate(for: .mockRevoked))
    }

    func testThatItsFalse_whenCertificateIsValid() {
        let e2eIdentityProvider = E2eIdentityProvider(gracePeriod: 0,
                                                      coreCryptoProvider: MockCoreCryptoProviderProtocol(),
                                                      conversationId: Data())
        XCTAssertFalse(e2eIdentityProvider.shouldUpdateCertificate(for: .mockValid))
    }

    func testThatItReturnsTrue_giveOnlyFewDaysAreLeftwhenShouldUpdateCertificateIsCalled() {
       let e2eIdentityProvider = E2eIdentityProvider(gracePeriod: 0,
                                                     coreCryptoProvider: MockCoreCryptoProviderProtocol(),
                                                     conversationId: Data())
       let certificate =  E2eIdentityCertificate(
            certificateDetails: .mockCertificate(),
            mlsThumbprint: "AB CD EF GH IJ KL MN OP QR ST UV WX",
            notValidBefore: Date.now - .oneDay,
            expiryDate: Date.now + .oneDay,
            certificateStatus: .expired,
            serialNumber: .mockSerialNumber
        )
        XCTAssertTrue(e2eIdentityProvider.shouldUpdateCertificate(for: certificate))
    }
}
