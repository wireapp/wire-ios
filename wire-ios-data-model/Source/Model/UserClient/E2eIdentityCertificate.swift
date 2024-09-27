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
import WireCoreCrypto

// MARK: - E2EIdentityCertificateStatus

public enum E2EIdentityCertificateStatus: CaseIterable {
    case notActivated
    case revoked
    case expired
    case invalid
    case valid
}

// MARK: - E2eIdentityCertificateConstants

public enum E2eIdentityCertificateConstants {
    // Maximum time messages are stored for a client on the backend
    public static let serverRetainedDays: TimeInterval = 28 * TimeInterval.oneDay

    // Randomising time so that not all clients update certificate at the same time
    public static let randomInterval: TimeInterval = .random(in: 0 ..< TimeInterval.oneDay)
}

// MARK: - E2eIdentityCertificate

@objc
public class E2eIdentityCertificate: NSObject {
    // MARK: Lifecycle

    public init(
        clientId: String,
        certificateDetails: String,
        mlsThumbprint: String,
        notValidBefore: Date,
        expiryDate: Date,
        certificateStatus: E2EIdentityCertificateStatus,
        serialNumber: String,
        comparedDate: CurrentDateProviding = SystemDateProvider(),
        serverStoragePeriod: TimeInterval = E2eIdentityCertificateConstants.serverRetainedDays,
        randomPeriod: TimeInterval = E2eIdentityCertificateConstants.randomInterval
    ) {
        self.clientId = clientId
        self.details = certificateDetails
        self.mlsThumbprint = mlsThumbprint
        self.notValidBefore = notValidBefore
        self.expiryDate = expiryDate
        self.status = certificateStatus
        self.serialNumber = serialNumber
        self.comparedDate = comparedDate
        self.serverStoragePeriod = serverStoragePeriod
        self.randomPeriod = randomPeriod
    }

    // MARK: Public

    public struct DateProvider: CurrentDateProviding {
        // MARK: Lifecycle

        public init(now: Date) {
            self.now = now
        }

        // MARK: Public

        public let now: Date
    }

    public var clientId: String
    public var details: String
    public var mlsThumbprint: String
    public var notValidBefore: Date
    public var expiryDate: Date
    public var status: E2EIdentityCertificateStatus
    public var serialNumber: String
    public var comparedDate: CurrentDateProviding
    public var serverStoragePeriod: TimeInterval
    public var randomPeriod: TimeInterval
}

extension E2eIdentityCertificate {
    private var isExpired: Bool {
        expiryDate <= comparedDate.now
    }

    private var isValid: Bool {
        status == .valid
    }

    private var isActivated: Bool {
        notValidBefore <= comparedDate.now
    }

    public func shouldUpdate(with gracePeriod: TimeInterval) -> Bool {
        let renewalNudgingDate = renewalNudgingDate(with: gracePeriod)
        return isExpired || (isActivated && comparedDate.now >= renewalNudgingDate)
    }

    /// In order to get `renewalNudgingDate` we should deduct standard deductions from Validity Period (VP) and add it
    /// to `notValidBefore` date
    /// Standard deductions are : Server storage time(HT), Grace period set by team admin(GP),  Random time in a day(UT)
    /// Renewal nudging date = VP - (HT + GP + UT)
    /// Here we calculate it from the other way where we deduct the standard deductions from the expiry date to get the
    /// renewal nudging date
    /// This is done so as to be in sync with Android codebase
    public func renewalNudgingDate(with gracePeriod: TimeInterval) -> Date {
        let standardDeductionsFromExpiry = serverStoragePeriod + gracePeriod + randomPeriod
        return expiryDate - standardDeductionsFromExpiry
    }
}
