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
import WireSyncEngine
import WireSystem

public protocol E2EINotificationActions {

    func getCertificate() async
    func updateCertificate() async
    func snoozeReminder() async

}

final class E2EINotificationActionsHandler: E2EINotificationActions {

    // MARK: - Properties

    private var enrollCertificateUseCase: EnrollE2EICertificateUseCaseProtocol
    private var snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol
    private var stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol
    private let gracePeriodRepository: GracePeriodRepository
    private let targetVC: UIViewController

    // MARK: - Life cycle

    init(
        enrollCertificateUseCase: EnrollE2EICertificateUseCaseProtocol,
        snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol,
        stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol,
        gracePeriodRepository: GracePeriodRepository,
        targetVC: UIViewController) {
            self.enrollCertificateUseCase = enrollCertificateUseCase
            self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
            self.stopCertificateEnrollmentSnoozerUseCase = stopCertificateEnrollmentSnoozerUseCase
            self.gracePeriodRepository = gracePeriodRepository
            self.targetVC = targetVC
        }

    public func getCertificate() async {
        let oauthUseCase = OAuthUseCase(rootViewController: targetVC)
        do {
            let certificateDetails = try await enrollCertificateUseCase.invoke(authenticate: oauthUseCase.invoke)
            await confirmSuccessfulEnrollment(certificateDetails)
        } catch {
            guard let endOfGracePeriod = gracePeriodRepository.fetchGracePeriodEndDate() else {
                return
            }
            await showGetCertificateErrorAlert(canCancel: !endOfGracePeriod.isInThePast)
        }
    }

    public func updateCertificate() async {
        // TODO: [WPB-3324] update certificate
    }

    public func snoozeReminder() async {
        guard let endOfGracePeriod = gracePeriodRepository.fetchGracePeriodEndDate(),
              endOfGracePeriod.timeIntervalSinceNow > 0,
              let formattedDuration = durationFormatter.string(from: endOfGracePeriod.timeIntervalSinceNow) else {
            return
        }

        let alert = await UIAlertController.reminderGetCertificate(timeLeft: formattedDuration) {
            Task {
                await self.snoozeCertificateEnrollmentUseCase.invoke()
            }
        }
        await targetVC.present(alert, animated: true)
    }

    // MARK: - Helpers

    private func showGetCertificateErrorAlert(canCancel: Bool) async {
        let oauthUseCase = OAuthUseCase(rootViewController: targetVC)
        let alert = await UIAlertController.getCertificateFailed(canCancel: canCancel) {
            Task {
                let certificateDetails = try await self.enrollCertificateUseCase.invoke(authenticate: oauthUseCase.invoke)
                await self.confirmSuccessfulEnrollment(certificateDetails)
            }
        }
        await targetVC.present(alert, animated: true)
    }

    @MainActor
    private func confirmSuccessfulEnrollment(_ certificateDetails: String) async {
        await snoozeCertificateEnrollmentUseCase.invoke()
        let successScreen = SuccessfulCertificateEnrollmentViewController()
        successScreen.certificateDetails = certificateDetails
        successScreen.onOkTapped = { viewController in
            viewController.dismiss(animated: true)
        }

        targetVC.present(successScreen, animated: true)
    }

    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

}

private extension UIAlertController {

    static func getCertificateFailed(
        canCancel: Bool,
        completion: @escaping () -> Void) -> UIAlertController {
            typealias Alert = L10n.Localizable.FailetToGetCertificate.Alert
            typealias Button = L10n.Localizable.FailetToGetCertificate.Button

            let title = Alert.title
            let message = canCancel ? Alert.message : Alert.forcedMessage
            let controller = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )

            let tryAgainAction = UIAlertAction(
                title: Button.retry,
                style: .default,
                handler: { _ in completion() }
            )

            controller.addAction(tryAgainAction)
            if canCancel {
                controller.addAction(.cancel())
            }
            return controller
        }

    static func updateCertificateFailed(
        canCancel: Bool,
        completion: @escaping () -> Void) -> UIAlertController {
            typealias Alert = L10n.Localizable.FailetToUpdateCertificate.Alert
            typealias Button = L10n.Localizable.FailetToUpdateCertificate.Button

            let title = Alert.title
            let message = canCancel ? Alert.message : Alert.forcedMessage
            let controller = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )

            let tryAgainAction = UIAlertAction(
                title: Button.retry,
                style: .default,
                handler: { _ in completion() }
            )

            controller.addAction(tryAgainAction)
            if canCancel {
                controller.addAction(.cancel())
            }
            return controller
        }

    static func reminderGetCertificate(
        timeLeft: String,
        completion: @escaping () -> Void) -> UIAlertController {
            typealias Alert = L10n.Localizable.FeatureConfig.Alert.MlsE2ei

            let controller = UIAlertController(
                title: nil,
                message: Alert.reminderMessage(timeLeft),
                preferredStyle: .alert
            )

            let okAction = UIAlertAction(
                title: Alert.Button.ok,
                style: .default,
                handler: { _ in completion() }
            )

            controller.addAction(okAction)
            return controller
        }

}
