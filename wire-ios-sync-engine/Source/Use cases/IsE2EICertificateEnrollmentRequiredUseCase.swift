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

// MARK: - IsE2EICertificateEnrollmentRequiredProtocol

// sourcery: AutoMockable
public protocol IsE2EICertificateEnrollmentRequiredProtocol {
    func invoke() async throws -> Bool
}

// MARK: - IsE2EICertificateEnrollmentRequiredUseCase

public final class IsE2EICertificateEnrollmentRequiredUseCase: IsE2EICertificateEnrollmentRequiredProtocol {
    // MARK: - Properties

    private let isE2EIdentityEnabled: Bool
    private let selfClientCertificateProvider: SelfClientCertificateProviderProtocol
    private let gracePeriodEndDate: Date?

    // MARK: - Life cycle

    init(
        isE2EIdentityEnabled: Bool,
        selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
        gracePeriodEndDate: Date?
    ) {
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
        self.selfClientCertificateProvider = selfClientCertificateProvider
        self.gracePeriodEndDate = gracePeriodEndDate
    }

    // MARK: - Methods

    public func invoke() async throws -> Bool {
        guard let gracePeriodEndDate else { return false }

        let hasCertificate = await selfClientCertificateProvider.hasCertificate
        return isE2EIdentityEnabled && !hasCertificate && gracePeriodEndDate.isInThePast
    }
}
