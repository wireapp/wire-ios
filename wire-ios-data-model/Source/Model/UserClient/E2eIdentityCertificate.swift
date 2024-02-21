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

import Foundation
import WireCoreCrypto

public enum E2EIdentityCertificateStatus: CaseIterable {
    case notActivated, revoked, expired, valid
}

@objc public class E2eIdentityCertificate: NSObject {

    public var clientId: String
    public var details: String
    public var mlsThumbprint: String
    public var notValidBefore: Date
    public var expiryDate: Date
    public var status: E2EIdentityCertificateStatus
    public var serialNumber: String
    public var comparedDate: Date
    public init(
        clientId: String,
        certificateDetails: String,
        mlsThumbprint: String,
        notValidBefore: Date,
        expiryDate: Date,
        certificateStatus: E2EIdentityCertificateStatus,
        serialNumber: String,
        comparedDate: Date = DateProvider(now: .now).now
    ) {
        self.clientId = clientId
        self.details = certificateDetails
        self.mlsThumbprint = mlsThumbprint
        self.notValidBefore = notValidBefore
        self.expiryDate = expiryDate
        self.status = certificateStatus
        self.serialNumber = serialNumber
        self.comparedDate = comparedDate
    }

    public struct DateProvider: DateProviding {
        public let now: Date

        public init(now: Date) {
            self.now = now
        }
    }

}
