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
import WireDataModel
import WireDomain
import WireFoundation
import WireLogging

public enum E2EIdentityCertificateUpdateStatus {

    // Alert was already shown within snooze period, so do not remind user to update certificate
    case noAction

    // Alert was not shown within snooze period, so remind user to update certificate
    case reminder

    // Certificate expired so soft block user to update certificate
    case block
}

// sourcery: AutoMockable
public protocol E2EIdentityCertificateUpdateStatusUseCaseProtocol {
    func invoke() async throws -> E2EIdentityCertificateUpdateStatus
}

public struct E2EIdentityCertificateUpdateStatusUseCase: E2EIdentityCertificateUpdateStatusUseCaseProtocol {

    public enum Failure: Error {

        /// E2EI is not enabled, so there's no certificate to update.
        case featureDisabled

        /// The self client is missing or doesn't have the information required to identify it in MLS.
        case missingSelfMLSClientID
    }

    private let getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol
    private let featureConfigRepository: any FeatureConfigRepositoryProtocol
    private let localDomain: String?
    private let comparedDate: CurrentDateProviding
    private let context: NSManagedObjectContext
    private let lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?

    public init(
        getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol,
        featureConfigRepository: any FeatureConfigRepositoryProtocol,
        localDomain: String?,
        context: NSManagedObjectContext,
        lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?,
        comparedDate: CurrentDateProviding = .system
    ) {
        self.getE2eIdentityCertificates = getE2eIdentityCertificates
        self.featureConfigRepository = featureConfigRepository
        self.localDomain = localDomain
        self.lastE2EIUpdateDateRepository = lastE2EIUpdateDateRepository
        self.context = context
        self.comparedDate = comparedDate
    }

    /// - Throws: `Failure.featureDisabled` if E2EI is not enabled. The feature state and the self client are
    ///   read on every invocation, so the use case can be created before E2EI gets enabled.
    public func invoke() async throws -> E2EIdentityCertificateUpdateStatus {

        let e2eiFeature = try await featureConfigRepository.fetchE2EIConfig()
        guard e2eiFeature.status == .enabled else { throw Failure.featureDisabled }

        let mlsClientID = await context.perform {
            ZMUser.selfUser(in: context).selfClient().flatMap {
                MLSClientID(userClient: $0, localDomain: localDomain)
            }
        }
        guard let mlsClientID else { throw Failure.missingSelfMLSClientID }

        let verificationExpiration = e2eiFeature.config?.verificationExpiration ?? Feature.E2EI.Config()
            .verificationExpiration
        let gracePeriod = TimeInterval(verificationExpiration)

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

        guard certificate.isEnrolled else {
            // No certificate has ever been enrolled, so there's nothing to update or expire.
            // Enrollment is nudged separately (see IsE2EICertificateEnrollmentRequiredUseCase).
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
}
