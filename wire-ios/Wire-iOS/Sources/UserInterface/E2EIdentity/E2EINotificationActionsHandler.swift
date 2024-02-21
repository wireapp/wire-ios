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

public protocol E2EINotificationActions {

    func enrollCertificate()
    func snoozeReminder() async

}

final class E2EINotificationActionsHandler: E2EINotificationActions {

    // MARK: - Properties

    private var enrollCertificateUseCase: EnrollE2EICertificateUseCaseInterface?
    private var snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol?
    private var stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol?

    // MARK: - Life cycle

    init(enrollCertificateUseCase: EnrollE2EICertificateUseCaseInterface?,
         snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol?,
         stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol?) {
        self.enrollCertificateUseCase = enrollCertificateUseCase
        self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
        self.stopCertificateEnrollmentSnoozerUseCase = stopCertificateEnrollmentSnoozerUseCase
    }

    public func enrollCertificate() {
        // TODO: [WPB-5496] enroll certificate
        stopCertificateEnrollmentSnoozerUseCase?.invoke()
    }

    public func snoozeReminder() async {
        await snoozeCertificateEnrollmentUseCase?.invoke()
    }

}
