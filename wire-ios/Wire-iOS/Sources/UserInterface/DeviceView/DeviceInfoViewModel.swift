//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

struct E2EIdentityCertificate {
    var status: E2EIdentityCertificateStatus
    var serialNumber: String
    var certificate: String = .randomString(length: 500)
}

enum E2EIdentityCertificateStatus: CaseIterable {
    case notActivated, revoked, expired, valid, none
}

extension E2EIdentityCertificateStatus {
    func titleForStatus() -> String {
        switch self {
        case .notActivated:
            return "Not activated"
        case .revoked:
            return "Revoked"
        case .expired:
            return "Expired"
        case .valid:
            return "Valid"
        case .none:
            return ""
        }
    }
}

struct DeviceInfoViewModel {
    let udid: String
    let addedDate: String = Date().formattedDate
    var title: String
    let mlsThumbprint: String
    let deviceKeyFingerprint: String
    let proteusID: String
    var isProteusVerificationEnabled: Bool
    var e2eIdentityCertificate: E2EIdentityCertificate
}

extension DeviceInfoViewModel: Identifiable {
    var id: String {
        return udid
    }
}

struct DevicesViewModel {
    var currentDevice: DeviceInfoViewModel
    var otherDevices: [DeviceInfoViewModel]
}
