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
    // Alert was already shown within snooze period, so do not remind user to update certificate
    case noAction

    // Alert was not  shown within snooze period, so remind user to update certificate
    case reminder

    // certificate expired so soft block user to update certificate
    case block
}

// sourcery: AutoMockable
public protocol E2EIdentityCertificateUpdateStatusUseCaseProtocol {
    func invoke() async throws -> E2EIdentityCertificateUpdateStatus
}

public struct E2EIdentityCertificateUpdateStatusUseCase: E2EIdentityCertificateUpdateStatusUseCaseProtocol {

    private let getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol
    private let gracePeriod: TimeInterval
    private let comparedDate: DateProviding
    private let mlsClientID: MLSClientID
    private let gracePeriodRepository: GracePeriodRepositoryInterface
    private let mlsGroupIDProvider: MLSGroupIDProviding
    public var lastAlertDate: Date?

    public init(
        getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol,
        gracePeriod: TimeInterval,
        mlsClientID: MLSClientID,
        lastAlertDate: Date?,
        comparedDate: DateProviding = SystemDateProvider(),
        gracePeriodRepository: GracePeriodRepositoryInterface,
        mlsGroupIDProvider: MLSGroupIDProviding
    ) {
        self.getE2eIdentityCertificates = getE2eIdentityCertificates
        self.gracePeriod = gracePeriod
        self.lastAlertDate = lastAlertDate
        self.mlsClientID = mlsClientID
        self.comparedDate = comparedDate
        self.gracePeriodRepository = gracePeriodRepository
        self.mlsGroupIDProvider = mlsGroupIDProvider
    }

    public func invoke() async throws -> E2EIdentityCertificateUpdateStatus {
        guard
            let mlsGroupID = await mlsGroupIDProvider.fetchMLSGroupID(),
            let certificate = try await getE2eIdentityCertificates.invoke(
            mlsGroupId: mlsGroupID,
            clientIds: [mlsClientID]
        ).first else {
            return .noAction
        }

        if certificate.expiryDate.isInThePast {
            return .block
        }

        let renewalNudgingDate = certificate.renewalNudgingDate(with: gracePeriod)
        if renewalNudgingDate > comparedDate.now && renewalNudgingDate < certificate.expiryDate {
            return .noAction
        }

        let fourHours = .oneHour * 4
        let fifteenMinutes = .fiveMinutes * 3

        let timeLeftUntilExpiration = certificate.expiryDate.timeIntervalSince(comparedDate.now)
        let maxTimeLeft = max(timeLeftUntilExpiration, TimeInterval.oneWeek)

        // Sets recurrring actions to check for the next reminder to update the certificate
        let snoozeTimeProvider = SnoozeTimeProvider()
        let snoozeTime = snoozeTimeProvider.getSnoozeTime(endOfPeriod: certificate.expiryDate)
        gracePeriodRepository.storeGracePeriodEndDate(Date.now + snoozeTime)

        // If not alert was shown before, show a reminder
        guard let lastAlertDate else {
            return .reminder
        }

        // this value would be negative as alert is shown in the past. Hence getting a positive value
        let lastAlertTimeInterval = abs(lastAlertDate.timeIntervalSinceNow)

        switch timeLeftUntilExpiration {

        case .oneDay ..< maxTimeLeft where lastAlertTimeInterval > .oneDay:
            return .reminder

        case fourHours ..< .oneDay where lastAlertTimeInterval > fourHours:
            return .reminder

        case .oneHour ..< fourHours where lastAlertTimeInterval > .oneHour:
            return .reminder

        case fifteenMinutes ..< .oneHour where lastAlertTimeInterval > fifteenMinutes:
            return .reminder

        case 0 ..< fifteenMinutes where lastAlertTimeInterval > .fiveMinutes:
            return .reminder

        default:
            return .noAction
        }

    }

}
