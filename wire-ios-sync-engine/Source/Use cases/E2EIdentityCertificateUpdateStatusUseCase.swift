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

public enum E2EIdentityCertificateUpdateStatus {
    case noAction, reminder, block
}

// sourcery: AutoMockable
public protocol E2EIdentityCertificateUpdateStatusProtocol {
    func invoke() async throws -> E2EIdentityCertificateUpdateStatus
}
public extension Notification.Name {
    static let checkForE2EICertificateStatus = NSNotification.Name("CheckForE2EICertificateStatus")
}

final public class E2EIdentityCertificateUpdateStatusUseCase: E2EIdentityCertificateUpdateStatusProtocol {

    private let e2eCertificateForCurrentClient: GetE2eIdentityCertificatesUseCaseProtocol
    private let gracePeriod: TimeInterval
    private let serverStoragePeriod: TimeInterval
    private let randomPeriod: TimeInterval
    private let lastAlertDate: Date?
    private let mlsGroupID: MLSGroupID
    private let mlsClientID: MLSClientID

    public init(
        e2eCertificateForCurrentClient: GetE2eIdentityCertificatesUseCaseProtocol,
        gracePeriod: TimeInterval,
        serverStoragePeriod: TimeInterval = 28 * TimeInterval.oneDay,
        randomPeriod: TimeInterval = Double((0..<Int(TimeInterval.oneDay)).randomElement() ?? 0), // Random time in a day
        mlsGroupID: MLSGroupID,
        mlsClientID: MLSClientID,
        lastAlertDate: Date?
    ) {
        self.e2eCertificateForCurrentClient = e2eCertificateForCurrentClient
        self.gracePeriod = gracePeriod
        self.lastAlertDate = lastAlertDate
        self.serverStoragePeriod = serverStoragePeriod
        self.randomPeriod = randomPeriod
        self.mlsGroupID = mlsGroupID
        self.mlsClientID = mlsClientID
    }

    public func invoke() async throws -> E2EIdentityCertificateUpdateStatus {
        if let certificate = try await e2eCertificateForCurrentClient.invoke(
            mlsGroupId: mlsGroupID,
            clientIds: [mlsClientID]
           ).first {

            if certificate.expiryDate.isInThePast {
                return .block
            }
            let timeLeft = certificate.expiryDate.timeIntervalSinceNow - serverStoragePeriod - gracePeriod - randomPeriod
            let calendar = Calendar.current
            let fourHours = .oneHour * 4
            let fifteenMinutes = .fiveMinutes * 3

            if timeLeft <= 0 {
                return .block
            }

            switch timeLeft {
            case  .oneDay ..< .oneWeek:
                if let lastAlertDate = lastAlertDate, calendar.isDateInToday(lastAlertDate) {
                    return .noAction
                }
                return .reminder
            case fourHours ..< .oneDay:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < fourHours {
                    return .noAction
                }
                return .reminder
            case .oneHour ..< fourHours:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < .oneHour {
                    return .noAction
                }
                return .reminder
            case fifteenMinutes ..< .oneHour:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < fifteenMinutes {
                    return .noAction
                }
                return .reminder

            case 1 ..< fifteenMinutes:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < .fiveMinutes {
                    return .noAction
                }
                return .reminder
            default:
                return .noAction
            }

        }
        return .noAction
    }

}
