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

// sourcery: AutoMockable
public protocol SnoozeCertificateEnrollmentUseCaseProtocol {
    func start(with gracePeriod: TimeInterval) async
    func remove()
}

final class SnoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol {

    // MARK: - Properties

    private let e2eiFeature: Feature.E2EI
    private let gracePeriodRepository: GracePeriodRepository
    private let recurringActionService: RecurringActionServiceInterface
    private let selfClientCertificateProvider: SelfClientCertificateProviderProtocol
    private let actionId: String

    // MARK: - Life cycle

    init(e2eiFeature: Feature.E2EI,
         gracePeriodRepository: GracePeriodRepository,
         recurringActionService: RecurringActionServiceInterface,
         selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
         accountId: UUID) {
        self.e2eiFeature = e2eiFeature
        self.gracePeriodRepository = gracePeriodRepository
        self.recurringActionService = recurringActionService
        self.selfClientCertificateProvider = selfClientCertificateProvider
        self.actionId = "\(accountId).enrollCertificate"
    }

    // MARK: - Methods

    func start(with gracePeriod: TimeInterval) async {
        let timeProvider = SnoozeTimeProvider()
        let endOfGracePeriod = fetchEndOfGracePeriod(gracePeriod)
        let interval = timeProvider.getSnoozeTime(endOfPeriod: endOfGracePeriod)

        await registerRecurringActionIfNeeded(interval: interval, gracePeriod: gracePeriod)
    }

    func remove() {
        recurringActionService.removeAction(id: actionId)
    }

    // MARK: - Helpers

    private func fetchEndOfGracePeriod(_ gracePeriod: TimeInterval) -> Date {
        /// The grace period end date should be saved once and not overwritten
        /// because it depends on when the user receives the grace period info.
        guard let endOfGracePeriod = gracePeriodRepository.fetchEndGracePeriodDate() else {
            let newEndOfGracePeriod = Date.now.addingTimeInterval(gracePeriod)
            gracePeriodRepository.storeEndGracePeriodDate(newEndOfGracePeriod)

            return newEndOfGracePeriod
        }
        return endOfGracePeriod
    }

    private func registerRecurringActionIfNeeded(interval: TimeInterval, gracePeriod: TimeInterval) async {
        guard e2eiFeature.isEnabled,
              await !selfClientCertificateProvider.hasCertificate else {
            return
        }

        let recurringAction = RecurringAction(
            id: actionId,
            interval: interval
        ) {
            let notificationObject = FeatureRepository.FeatureChange.e2eIEnabled(gracePeriod: gracePeriod)
            NotificationCenter.default.post(name: .featureDidChangeNotification,
                                            object: notificationObject)
        }

        recurringActionService.registerAction(recurringAction)
    }

}

final class SnoozeTimeProvider {

    // MARK: - Properties

    private let dateProvider: DateProviding

    // MARK: - Life cycle

    init(dateProvider: DateProviding = .system) {
        self.dateProvider = dateProvider
    }

    func getSnoozeTime(endOfPeriod: Date) -> TimeInterval {
        let timeLeft = dateProvider.now.distance(to: endOfPeriod)

        let fourHours = .oneHour * 4
        let fifteenMinutes = .fiveMinutes * 3

        switch timeLeft {
        case _ where timeLeft > .oneDay:
            return .oneDay
        case .oneDay ..< fourHours:
            return fourHours
        case fourHours ..< .oneHour:
            return .oneHour
        case .oneHour ..< fifteenMinutes:
            return fifteenMinutes
        default:
            return .fiveMinutes
        }
    }

}
