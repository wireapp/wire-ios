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

// MARK: - StopCertificateEnrollmentSnoozerUseCaseProtocol

// sourcery: AutoMockable
public protocol StopCertificateEnrollmentSnoozerUseCaseProtocol {
    func invoke()
}

// MARK: - StopCertificateEnrollmentSnoozerUseCase

final class StopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol {
    // MARK: - Properties

    private let recurringActionService: RecurringActionServiceInterface
    private let actionId: String

    // MARK: - Life cycle

    init(
        recurringActionService: RecurringActionServiceInterface,
        accountId: UUID
    ) {
        self.recurringActionService = recurringActionService
        self.actionId = "\(accountId).enrollCertificate"
    }

    // MARK: - Methods

    func invoke() {
        recurringActionService.removeAction(id: actionId)
    }
}
