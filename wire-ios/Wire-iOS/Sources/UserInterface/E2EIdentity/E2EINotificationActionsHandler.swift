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
    private var lastE2EIdentityUpdateAlertDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?
    private var e2eIdentityCertificateUpdateStatus: E2EIdentityCertificateUpdateStatusUseCaseProtocol?
    private var isUpdateMode: Bool = false
    // MARK: - Life cycle
    private var observer: NSObjectProtocol?
    init(
        enrollCertificateUseCase: EnrollE2EICertificateUseCaseProtocol,
        snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol,
        stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol,
        gracePeriodRepository: GracePeriodRepository,
        lastE2EIdentityUpdateAlertDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?,
        e2eIdentityCertificateUpdateStatus: E2EIdentityCertificateUpdateStatusUseCaseProtocol?,
        targetVC: UIViewController) {
            self.enrollCertificateUseCase = enrollCertificateUseCase
            self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
            self.stopCertificateEnrollmentSnoozerUseCase = stopCertificateEnrollmentSnoozerUseCase
            self.gracePeriodRepository = gracePeriodRepository
            self.lastE2EIdentityUpdateAlertDateRepository = lastE2EIdentityUpdateAlertDateRepository
            self.e2eIdentityCertificateUpdateStatus = e2eIdentityCertificateUpdateStatus
            self.targetVC = targetVC

            self.observer = NotificationCenter.default.addObserver(
                forName: .checkForE2EICertificateExpiryStatus,
                object: nil,
                queue: .main
            ) { _ in
                Task { [weak self] in
                    await self?.updateCertificate()
                }
            }
        }

    deinit {
        guard let observer else { return }
        NotificationCenter.default.removeObserver(observer)
    }

    public func getCertificate() async {
        let oauthUseCase = OAuthUseCase(targetViewController: targetVC)
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
        do {
            guard let result = try await e2eIdentityCertificateUpdateStatus?.invoke() else { return }

            switch result {
            case .noAction:
                isUpdateMode = false
                return

            case .reminder:
                isUpdateMode = true
                await showUpdateE2EIdentityCertificateAlert()

            case .block:
                isUpdateMode = true
                await showUpdateE2EIdentityCertificateAlert(canRemindLater: false)
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
            Task { [weak self] in

                guard let self else { return }

                await self.snoozeCertificateEnrollmentUseCase.invoke(isUpdateMode: self.isUpdateMode)
                self.isUpdateMode = false
            }
        }
        await targetVC.present(alert, animated: true)
    }

    // MARK: - Helpers

    private func showGetCertificateErrorAlert(canCancel: Bool) async {
        let oauthUseCase = OAuthUseCase(targetViewController: targetVC)
        let alert = await UIAlertController.getCertificateFailed(canCancel: canCancel, isUpdateMode: isUpdateMode) {
            Task { [weak self] in
                guard let self else { return }
                do {
                    let certificateDetails = try await self.enrollCertificateUseCase.invoke(
                        authenticate: oauthUseCase.invoke)
                    await self.confirmSuccessfulEnrollment(certificateDetails)
                } catch {
                    WireLogger.e2ei.error(
                        "failed to \(self.isUpdateMode ? "update" : "get") E2EI certification status: \(error)"
                    )
                }
                self.isUpdateMode = false
            }
        } cancelled: {[weak self] in
            self?.isUpdateMode = false
        }
        await targetVC.present(alert, animated: true)
    }

    @MainActor
    private func confirmSuccessfulEnrollment(_ certificateDetails: String) async {
        lastE2EIdentityUpdateAlertDateRepository?.storeLastAlertDate(Date.now)
        await snoozeCertificateEnrollmentUseCase.invoke(isUpdateMode: isUpdateMode)
        let successScreen = SuccessfulCertificateEnrollmentViewController(isUpdateMode: isUpdateMode)
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
        typealias E2EIUpdateStrings = L10n.Localizable.UpdateCertificate.Alert

        let alert = UIAlertController.alertForE2eIChangeWithActions(
            title: E2EIUpdateStrings.title,
            message: canRemindLater ? E2EIUpdateStrings.message : E2EIUpdateStrings.expiredMessage,
            enrollButtonText: E2EIUpdateStrings.title,
            canRemindLater: canRemindLater
        ) { action in
            switch action {
            case .getCertificate:
                Task {[weak self] in
                    await self?.getCertificate()
                }
            case .remindLater:
                Task { [weak self] in
                    await self?.snoozeReminder()
                }
            }
            self.lastE2EIdentityUpdateAlertDateRepository?.storeLastAlertDate(Date.now)
        }
        targetVC.present(alert, animated: true)
    }
}

private extension UIAlertController {

    static func getCertificateFailed(
        canCancel: Bool,
        isUpdateMode: Bool,
        completion: @escaping () -> Void,
        cancelled: @escaping () -> Void) -> UIAlertController {
            typealias UpdateAlert = L10n.Localizable.FailedToUpdateCertificate.Alert
            typealias Alert = L10n.Localizable.FailedToGetCertificate.Alert
            typealias Button = L10n.Localizable.FailedToGetCertificate.Button

            let title = isUpdateMode ? UpdateAlert.title : Alert.title
            let detail = isUpdateMode ? UpdateAlert.message : Alert.message
            let message = canCancel ? detail : Alert.forcedMessage
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
                controller.addAction(.cancel(cancelled))
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
