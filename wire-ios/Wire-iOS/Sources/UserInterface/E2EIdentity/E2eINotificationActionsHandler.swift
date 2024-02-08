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

    func enrollCertificate()
    func snoozeReminder(during gracePeriod: TimeInterval)

}

final class E2eINotificationActionsHandler: E2eINotificationActions {

    // MARK: - Properties

    private var enrollCertificateUseCase: EnrollE2eICertificateUseCaseInterface?
    private var snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol?

    // MARK: - Life cycle

    init(enrollCertificateUseCase: EnrollE2eICertificateUseCaseInterface?,
         snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol?) {
        self.enrollCertificateUseCase = enrollCertificateUseCase
        self.snoozeCertificateEnrollmentUseCase = snoozeCertificateEnrollmentUseCase
    }

    public func enrollCertificate() {
        // TODO: [WPB-5496] enroll certificate
        snoozeCertificateEnrollmentUseCase?.remove()
    }

    public func snoozeReminder(during gracePeriod: TimeInterval) {
        snoozeCertificateEnrollmentUseCase?.start(with: gracePeriod)
    }

}
