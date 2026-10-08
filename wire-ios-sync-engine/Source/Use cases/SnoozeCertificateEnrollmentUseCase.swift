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
import WireFoundation

// sourcery: AutoMockable
public protocol SnoozeCertificateEnrollmentUseCaseProtocol {
    func invoke(endOfPeriod: Date, isUpdateMode: Bool, onReminderDue: @escaping () async -> Void) async
}

final class SnoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol {

    // MARK: - Properties

    private let featureRepository: LegacyFeatureRepositoryInterface
    private let featureRepositoryContext: NSManagedObjectContext
    private let recurringActionService: RecurringActionServiceInterface
    private let actionId: String

    // MARK: - Life cycle

    init(
        featureRepository: LegacyFeatureRepositoryInterface,
        featureRepositoryContext: NSManagedObjectContext,
        recurringActionService: RecurringActionServiceInterface,
        accountId: UUID
    ) {
        self.featureRepository = featureRepository
        self.featureRepositoryContext = featureRepositoryContext
        self.recurringActionService = recurringActionService
        self.actionId = "\(accountId).enrollCertificate"
    }

    // MARK: - Methods

    /// Schedules recurring actions to check for enrolling or updating E2EI certificate
    /// - Parameter isUpdateMode: If set to `true`, `checkForE2EICertificateExpiryStatus` to check for updating
    /// certificate is scheduled else `onReminderDue` is invoked to check for enrolling the certificate. By default,
    /// this is `false`.
    /// - Parameter onReminderDue: Invoked when the enrollment reminder becomes due (ignored when `isUpdateMode` is
    /// `true`).
    func invoke(endOfPeriod: Date, isUpdateMode: Bool = false, onReminderDue: @escaping () async -> Void) async {
        let timeProvider = SnoozeTimeProvider()
        let interval = timeProvider.getSnoozeTime(endOfPeriod: endOfPeriod)
        await registerRecurringActionIfNeeded(isUpdateMode: isUpdateMode, interval: interval, onReminderDue: onReminderDue)
    }

    // MARK: - Helpers

    private func registerRecurringActionIfNeeded(
        isUpdateMode: Bool,
        interval: TimeInterval,
        onReminderDue: @escaping () async -> Void
    ) async {
        let isE2EIEnabled = await featureRepositoryContext.perform {
            self.featureRepository.fetchE2EI().isEnabled
        }
        guard isE2EIEnabled else { return }

        let recurringAction = RecurringAction(
            id: actionId,
            shouldRunEveryLaunch: false,
            interval: interval
        ) {
            if isUpdateMode {
                NotificationCenter.default.post(name: .checkForE2EICertificateExpiryStatus, object: nil)
            } else {
                await onReminderDue()
            }
        }

        recurringActionService.registerAction(recurringAction)
    }

}

final class SnoozeTimeProvider {

    // MARK: - Properties

    private let dateProvider: CurrentDateProviding

    // MARK: - Life cycle

    init(dateProvider: CurrentDateProviding = .system) {
        self.dateProvider = dateProvider
    }

    func getSnoozeTime(endOfPeriod: Date) -> TimeInterval {
        let timeLeft = dateProvider.now.distance(to: endOfPeriod)

        let fourHours = .oneHour * 4
        let fifteenMinutes = .fiveMinutes * 3

        switch timeLeft {
        case _ where timeLeft < fifteenMinutes:
            return .fiveMinutes
        case fifteenMinutes ..< .oneHour:
            return fifteenMinutes
        case .oneHour ..< fourHours:
            return .oneHour
        case fourHours ..< .oneDay:
            return fourHours
        case _ where timeLeft > .oneDay:
            return .oneDay
        default:
            return .oneDay
        }
    }

}
