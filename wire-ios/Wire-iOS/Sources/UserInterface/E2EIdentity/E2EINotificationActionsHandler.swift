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
    weak var userSession: UserSession?
    private var isUpdateMode: Bool = false
    // MARK: - Life cycle

    init(
        enrollCertificateUseCase: EnrollE2EICertificateUseCaseProtocol,
        snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol,
        stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol,
        gracePeriodRepository: GracePeriodRepository,
        userSession: UserSession?,
        targetVC: UIViewController) {
            self.enrollCertificateUseCase = enrollCertificateUseCase
            self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
            self.stopCertificateEnrollmentSnoozerUseCase = stopCertificateEnrollmentSnoozerUseCase
            self.gracePeriodRepository = gracePeriodRepository
            self.userSession = userSession
            self.targetVC = targetVC

            NotificationCenter.default.addObserver(forName: .checkForE2EICertificateStatus, object: nil, queue: .main) { _ in
                Task {
                    await self.updateCertificate()
                }
            }
        }

    @MainActor
    public func getCertificate() async {
        let oauthUseCase = OAuthUseCase(rootViewController: targetVC)
        do {
            let certificateDetails = try await enrollCertificateUseCase.invoke(authenticate: oauthUseCase.invoke)
            await confirmSuccessfulEnrollment(certificateDetails)
        } catch {
            guard let endOfGracePeriod = gracePeriodRepository.fetchGracePeriodEndDate() else {
                return
            }
            showGetCertificateErrorAlert(canCancel: !endOfGracePeriod.isInThePast)
        }
    }

    @MainActor
    public func updateCertificate() async {
        do {
            guard let updateCertificateUseCase = await userSession?.e2eIdentityUpdateCertificateUpdateStatus() else {
                return
            }
            let result = try await updateCertificateUseCase.invoke()
            switch result {
            case .noAction:
                return
            case .reminder:
                isUpdateMode = true
                showUpdateE2EIdentityCertificateAlert()
            case .block:
                isUpdateMode = true
                showUpdateE2EIdentityCertificateAlert(canRemindLater: false)
            }
        } catch {
            WireLogger.e2ei.error(error.localizedDescription)
        }
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
            self.isUpdateMode = false
        }
        await targetVC.present(alert, animated: true)
    }

    // MARK: - Helpers
    @MainActor
    private func showGetCertificateErrorAlert(canCancel: Bool) {
        let oauthUseCase = OAuthUseCase(rootViewController: targetVC)
        let alert = UIAlertController.getCertificateFailed(canCancel: canCancel, isUpdateMode: isUpdateMode) {
            Task { [weak self] in
                guard let self else { return }
                do {
                    let certificateDetails = try await self.enrollCertificateUseCase.invoke(
                        authenticate: oauthUseCase.invoke)
                    await self.confirmSuccessfulEnrollment(certificateDetails)
                } catch {
                    WireLogger.e2ei.error("failed to \(self.isUpdateMode ? "update" : "get") E2EI certification status: \(error)")
                    isUpdateMode = false
                }
            }
        }
        targetVC.present(alert, animated: true)
    }

    @MainActor
    private func confirmSuccessfulEnrollment(_ certificateDetails: String) async {
        await snoozeCertificateEnrollmentUseCase.invoke()
        guard let lastE2EIdentityUpdateDate = userSession?.lastE2EIUpdateDate else {
            return
        }
        let successScreen = SuccessfulCertificateEnrollmentViewController(lastE2EIdentityUpdateDate: lastE2EIdentityUpdateDate)
        successScreen.isUpdateMode = isUpdateMode
        successScreen.certificateDetails = certificateDetails
        successScreen.onOkTapped = { viewController in
            viewController.dismiss(animated: true)
            self.isUpdateMode = false
        }

        targetVC.present(successScreen, animated: true)
    }

    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    @MainActor
    private func showUpdateE2EIdentityCertificateAlert(canRemindLater: Bool = true) {
        userSession?.lastE2EIUpdateDate?.storeLastAlertDate(Date.now)
        typealias MlsE2eiStrings = L10n.Localizable.FeatureConfig.Alert.MlsE2ei
        let alert = UIAlertController.alertForE2eIChangeWithActions(
            title: MlsE2eiStrings.Alert.UpdateCertificate.title,
            message: MlsE2eiStrings.updateMessage,
            enrollButtonText: MlsE2eiStrings.Button.updateCertificate,
            canRemindLater: canRemindLater
        ) { action in
            switch action {
            case .getCertificate:
                Task {
                    await self.getCertificate()
                }
            case .remindLater:
                Task {
                    await self.snoozeReminder()
                }
            }
        }
        targetVC.present(alert, animated: true)
    }
}

private extension UIAlertController {

    static func getCertificateFailed(
        canCancel: Bool,
        isUpdateMode: Bool,
        completion: @escaping () -> Void) -> UIAlertController {
            typealias UpdateAlert = L10n.Localizable.FailedToUpdateCertificate.Alert
            typealias Alert = L10n.Localizable.FailedToGetCertificate.Alert
            typealias Button = L10n.Localizable.FailedToGetCertificate.Button

            let title = isUpdateMode ? UpdateAlert.title : Alert.title
            let message = canCancel ? (isUpdateMode ? UpdateAlert.message : Alert.message) : Alert.forcedMessage
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
