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

// MARK: - E2EIdentityCertificateUpdateStatus

public enum E2EIdentityCertificateUpdateStatus {
    // Alert was already shown within snooze period, so do not remind user to update certificate
    case noAction

    // Alert was not shown within snooze period, so remind user to update certificate
    case reminder

    // Certificate expired so soft block user to update certificate
    case block
}

// MARK: - E2EIdentityCertificateUpdateStatusUseCaseProtocol

// sourcery: AutoMockable
public protocol E2EIdentityCertificateUpdateStatusUseCaseProtocol {
    func invoke() async throws -> E2EIdentityCertificateUpdateStatus
}

// MARK: - E2EIdentityCertificateUpdateStatusUseCase

public struct E2EIdentityCertificateUpdateStatusUseCase: E2EIdentityCertificateUpdateStatusUseCaseProtocol {
    // MARK: Lifecycle

    public init(
        getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol,
        gracePeriod: TimeInterval,
        mlsClientID: MLSClientID,
        context: NSManagedObjectContext,
        lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?,
        comparedDate: CurrentDateProviding = SystemDateProvider()
    ) {
        self.getE2eIdentityCertificates = getE2eIdentityCertificates
        self.gracePeriod = gracePeriod
        self.lastE2EIUpdateDateRepository = lastE2EIUpdateDateRepository
        self.mlsClientID = mlsClientID
        self.context = context
        self.comparedDate = comparedDate
    }

    // MARK: Public

    public func invoke() async throws -> E2EIdentityCertificateUpdateStatus {
        let selfMLSConversationGroupID = await context.perform {
            ZMConversation.fetchSelfMLSConversation(in: context)?.mlsGroupID
        }
        guard let selfMLSConversationGroupID else {
            WireLogger.e2ei.warn("Failed to get MLS group ID of the self-MLS-conversation.")
            return .noAction
        }

        let certificate = try await getE2eIdentityCertificates.invoke(
            mlsGroupId: selfMLSConversationGroupID,
            clientIds: [mlsClientID]
        ).first
        guard let certificate else {
            WireLogger.e2ei.warn("Failed to get the certificate for the self-MLS-conversation.")
            return .noAction
        }

        if certificate.expiryDate.isInThePast {
            return .block
        }

        let renewalNudgingDate = certificate.renewalNudgingDate(with: gracePeriod)
        if renewalNudgingDate > comparedDate.now, renewalNudgingDate < certificate.expiryDate {
            return .noAction
        }

        let fourHours = .oneHour * 4
        let fifteenMinutes = .fiveMinutes * 3

        let timeLeftUntilExpiration = certificate.expiryDate.timeIntervalSince(comparedDate.now)
        let maxTimeLeft = max(timeLeftUntilExpiration, TimeInterval.oneWeek)

        // If not alert was shown before, show a reminder
        guard let lastAlertDate = lastE2EIUpdateDateRepository?.fetchLastAlertDate() else {
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

    // MARK: Private

    private let getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol
    private let gracePeriod: TimeInterval
    private let comparedDate: CurrentDateProviding
    private let mlsClientID: MLSClientID
    private let context: NSManagedObjectContext
    private let lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?
}
