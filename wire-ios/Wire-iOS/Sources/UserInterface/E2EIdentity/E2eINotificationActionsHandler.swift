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

public protocol E2eINotificationActions {

    func getCertificate() async
    func updateCertificate() async
    func snoozeReminder() async

}

final class E2eINotificationActionsHandler: E2eINotificationActions {

    // MARK: - Properties

    private var enrollCertificateUseCase: EnrollE2eICertificateUseCaseInterface?
    private var snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol?
    private let gracePeriodRepository: GracePeriodRepository
    private let targetVC: UIViewController

    // MARK: - Life cycle

    init(enrollCertificateUseCase: EnrollE2eICertificateUseCaseInterface?,
         snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol?,
         gracePeriodRepository: GracePeriodRepository,
         targetVC: UIViewController) {
        self.enrollCertificateUseCase = enrollCertificateUseCase
        self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
        self.gracePeriodRepository = gracePeriodRepository
        self.targetVC = targetVC
    }

    public func getCertificate() async {
        let oauthUseCase = OAuthUseCase(rootViewController: targetVC)
        do {
            try await enrollCertificateUseCase?.invoke(authenticate: oauthUseCase.invoke)
            confirmSuccessfulEnrollment()
        } catch {
            guard let endOfGracePeriod = gracePeriodRepository.fetchEndGracePeriodDate() else {
                return
            }
            await showGetCertificateErrorAlert(canCancel: !endOfGracePeriod.isInThePast)
        }
    }

    public func updateCertificate() async {
        // TODO: [WPB-3324] update certificate
    }

    public func snoozeReminder() async {
        guard let endOfGracePeriod = gracePeriodRepository.fetchEndGracePeriodDate(),
              endOfGracePeriod.timeIntervalSinceNow > 0,
              let formattedDuration = durationFormatter.string(from: endOfGracePeriod.timeIntervalSinceNow) else {
            return
        }

        let alert = await UIAlertController.reminderGetCertificate(timeLeft: formattedDuration) {
            Task {
                await self.snoozeCertificateEnrollmentUseCase?.start()
            }
        }
    }

    // MARK: - Helpers

    private func showGetCertificateErrorAlert(canCancel: Bool) async {
        let alert = await UIAlertController.getCertificateFailed(canCancel: canCancel) {
            let oauthUseCase = OAuthUseCase(rootViewController: self.targetVC)
            Task {
                try await self.enrollCertificateUseCase?.invoke(authenticate: oauthUseCase.invoke)
            }
            self.confirmSuccessfulEnrollment()
        }
        await targetVC.present(alert, animated: true)
    }

    private func confirmSuccessfulEnrollment() {
        snoozeCertificateEnrollmentUseCase?.stop()
        // to show success screen
    }

    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

}

private extension UIAlertController {

    static func getCertificateFailed(canCancel: Bool, completion: @escaping () -> Void) -> UIAlertController {
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

    static func updateCertificateFailed(canCancel: Bool, completion: @escaping () -> Void) -> UIAlertController {
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

    static func reminderGetCertificate(timeLeft: String, completion: @escaping () -> Void) -> UIAlertController {
        typealias Alert = L10n.Localizable.FeatureConfig.Alert.MlsE2ei

        let message = Alert.message
        let controller = UIAlertController(
            title: nil,
            message: Alert.remiderMessage(timeLeft),
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

final class SuccessfulCertificateEnrollmentViewController: UIViewController {

    override func viewDidLoad() {
        setupViews()
    }

    func setupViews() {
    }

}
