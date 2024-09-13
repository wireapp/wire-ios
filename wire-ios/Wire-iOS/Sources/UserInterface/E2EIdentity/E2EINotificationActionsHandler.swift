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

protocol E2EINotificationActions {
    func getCertificate() async
    func updateCertificate() async
    func snoozeReminder() async
}

final class E2EINotificationActionsHandler: E2EINotificationActions {
    enum Failure: Error {
        case getCertificateError
    }

    // MARK: - Properties

    private var enrollCertificateUseCase: EnrollE2EICertificateUseCaseProtocol
    private var snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol
    private var stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol
    private let e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    private let e2eiFeature: Feature.E2EI
    private var lastE2EIdentityUpdateAlertDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?
    private var e2eIdentityCertificateUpdateStatus: E2EIdentityCertificateUpdateStatusUseCaseProtocol?
    private let selfClientCertificateProvider: SelfClientCertificateProviderProtocol
    private var isUpdateMode = false

    private let targetVC: () -> UIViewController
    private var observer: NSObjectProtocol?

    private weak var alertForE2EIChange: UIAlertController?

    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Life cycle

    init(
        enrollCertificateUseCase: EnrollE2EICertificateUseCaseProtocol,
        snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol,
        stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol,
        e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol,
        e2eiFeature: Feature.E2EI,
        lastE2EIdentityUpdateAlertDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?,
        e2eIdentityCertificateUpdateStatus: E2EIdentityCertificateUpdateStatusUseCaseProtocol?,
        selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
        targetVC: @escaping () -> UIViewController
    ) {
        self.enrollCertificateUseCase = enrollCertificateUseCase
        self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
        self.stopCertificateEnrollmentSnoozerUseCase = stopCertificateEnrollmentSnoozerUseCase
        self.e2eiActivationDateRepository = e2eiActivationDateRepository
        self.e2eiFeature = e2eiFeature
        self.lastE2EIdentityUpdateAlertDateRepository = lastE2EIdentityUpdateAlertDateRepository
        self.e2eIdentityCertificateUpdateStatus = e2eIdentityCertificateUpdateStatus
        self.selfClientCertificateProvider = selfClientCertificateProvider
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

    func getCertificate() async {
        let oauthUseCase = OAuthUseCase(targetViewController: targetVC)
        do {
            let certificateDetails = try await enrollCertificateUseCase.invoke(authenticate: oauthUseCase.invoke)
            stopCertificateEnrollmentSnoozerUseCase.invoke()
            await confirmSuccessfulEnrollment(certificateDetails)
        } catch {
            let canCancel = gracePeriodEndDate == nil || gracePeriodEndDate?.isInThePast == false
            await showGetCertificateErrorAlert(canCancel: canCancel, retry: getCertificate)
        }
    }

    @MainActor
    func updateCertificate() async {
        do {
            guard let result = try await e2eIdentityCertificateUpdateStatus?.invoke() else { return }

            switch result {
            case .noAction:
                isUpdateMode = false
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

    func snoozeReminder() async {
        let selfClientCertificate = try? await selfClientCertificateProvider.getCertificate()
        guard let endOfPeriod = selfClientCertificate?.expiryDate ?? gracePeriodEndDate,
              !endOfPeriod.isInThePast,
              let formattedDuration = durationFormatter.string(from: endOfPeriod.timeIntervalSinceNow) else {
            return
        }

        let alert = await UIAlertController.reminderGetCertificate(timeLeft: formattedDuration) {
            Task { [weak self] in

                guard let self else { return }

                await snoozeCertificateEnrollmentUseCase.invoke(
                    endOfPeriod: endOfPeriod,
                    isUpdateMode: isUpdateMode
                )
                isUpdateMode = false
            }
        }
        await presentScreen(viewController: alert)
    }

    // MARK: - Helpers

    /// Show error and retry if requested
    private func showGetCertificateErrorAlert(canCancel: Bool, retry: @escaping () async -> Void) async {
        let alert = await UIAlertController.getCertificateFailed(canCancel: canCancel, isUpdateMode: isUpdateMode) {
            Task { [weak self] in
                await retry()
                self?.isUpdateMode = false
            }

        } cancelled: { [weak self] in
            self?.isUpdateMode = false
        }
        await presentScreen(viewController: alert)
    }

    @MainActor
    private func confirmSuccessfulEnrollment(_ certificateDetails: String) {
        lastE2EIdentityUpdateAlertDateRepository?.storeLastAlertDate(Date.now)
        stopCertificateEnrollmentSnoozerUseCase.invoke()
        let successScreen = SuccessfulCertificateEnrollmentViewController(isUpdateMode: isUpdateMode)
        successScreen.certificateDetails = certificateDetails
        successScreen.onOkTapped = { viewController in
            viewController.dismiss(animated: true)
            self.isUpdateMode = false
        }

        presentScreen(viewController: successScreen)
    }

    @MainActor
    private func presentScreen(viewController: UIViewController) {
        let vc = UIApplication.shared.topmostViewController(onlyFullScreen: false) ?? targetVC()
        vc.present(viewController, animated: true)
    }

    @MainActor
    private func showUpdateE2EIdentityCertificateAlert(canRemindLater: Bool = true) {
        typealias E2EIUpdateStrings = L10n.Localizable.UpdateCertificate.Alert

        guard alertForE2EIChange == nil else { return }

        let alert = UIAlertController.alertForE2EIChangeWithActions(
            title: E2EIUpdateStrings.title,
            message: canRemindLater ? E2EIUpdateStrings.message : E2EIUpdateStrings.expiredMessage,
            enrollButtonText: E2EIUpdateStrings.title,
            canRemindLater: canRemindLater
        ) { action in

            switch action {
            case .getCertificate:
                Task { [weak self] in
                    await self?.getCertificate()
                }
            case .remindLater:
                Task { [weak self] in
                    await self?.snoozeReminder()
                }
            case .learnMore:
                break
            }
        }
        alertForE2EIChange = alert
        lastE2EIdentityUpdateAlertDateRepository?.storeLastAlertDate(Date.now)

        presentScreen(viewController: alert)
    }

    private var gracePeriodEndDate: Date? {
        guard let e2eiActivatedAt = e2eiActivationDateRepository.e2eiActivatedAt else {
            return nil
        }

        let gracePeriod = TimeInterval(e2eiFeature.config.verificationExpiration)
        return e2eiActivatedAt.addingTimeInterval(gracePeriod)
    }
}

extension UIAlertController {
    static func getCertificateFailed(
        canCancel: Bool,
        isUpdateMode: Bool,
        completion: @escaping () -> Void,
        cancelled: @escaping () -> Void
    ) -> UIAlertController {
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
        completion: @escaping () -> Void
    ) -> UIAlertController {
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
