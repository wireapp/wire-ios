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

enum E2EIdentityCertificateUpdateStatus {
    case noAction, reminder, block
}

protocol E2EIdentityCertificateUpdateStatusProtocol {
    func invoke() async throws -> E2EIdentityCertificateUpdateStatus
}

final class E2EIdentityCertificateUpdateStatusUseCase: E2EIdentityCertificateUpdateStatusProtocol {

    private let isE2EIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol
    private let e2eCertificateForCurrentClient: GetE2eIdentityCertificatesUseCaseProtocol
    private let mlsGroupID: MLSGroupID
    private let mlsClientID: MLSClientID
    private let gracePeriod: TimeInterval
    private let lastAlertDate: Date?

    init(
        isE2EIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol,
        e2eCertificateForCurrentClient: GetE2eIdentityCertificatesUseCaseProtocol,
        mlsGroupID: MLSGroupID,
        mlsClientID: MLSClientID,
        gracePeriod: TimeInterval,
        lastAlertDate: Date?
    ) {
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
        self.e2eCertificateForCurrentClient = e2eCertificateForCurrentClient
        self.mlsGroupID = mlsGroupID
        self.mlsClientID = mlsClientID
        self.gracePeriod = gracePeriod
        self.lastAlertDate = lastAlertDate
    }

    func invoke() async throws -> E2EIdentityCertificateUpdateStatus {
        let isE2EIdentityEnabled = try await isE2EIdentityEnabled.invoke()
        if isE2EIdentityEnabled,
           let certificate = try await e2eCertificateForCurrentClient.invoke(
            mlsGroupId: mlsGroupID,
            clientIds: [mlsClientID]
           ).first {
            let timeLeft = certificate.expiryDate.timeIntervalSinceNow
            let calendar = Calendar.current
            if certificate.expiryDate.isInThePast {
                return .block
            }
            let fourHours = .oneHour * 4
            let fifteenMinutes = .fiveMinutes * 3

            switch timeLeft {
            case  .oneDay ..< .oneWeek:
                if let lastAlertDate = lastAlertDate, calendar.isDateInToday(lastAlertDate) {
                    return .noAction
                }
                return .reminder
            case fourHours ..< .oneDay:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < fourHours {
                    return .noAction
                }
                return .reminder
            case .oneHour ..< fourHours:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < .oneHour {
                    return .noAction
                }
                return .reminder
            case fifteenMinutes ..< .oneHour:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < fifteenMinutes {
                    return .noAction
                }
                return .reminder

            case 1 ..< fifteenMinutes:
                if let lastAlertDate = lastAlertDate, lastAlertDate.timeIntervalSinceNow < .fiveMinutes {
                    return .noAction
                }
                return .reminder
            case 0:
                return .block
            default:
                return .noAction
            }

        }
        return .noAction
    }
}
