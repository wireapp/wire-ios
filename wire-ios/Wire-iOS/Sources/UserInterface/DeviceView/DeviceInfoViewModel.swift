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
import SwiftUI
import WireCommonComponents
import WireDataModel
import WireSyncEngine

protocol DeviceDetailsViewActions {
    func fetchCertificate() async -> E2eIdentityCertificate?
    func showCertificate(
        _ certificate: String
    )
    func removeDevice() async -> Bool
    func resetSession() async -> Bool
    func updateVerified(_ value: Bool) async -> Bool
    var isProcessing: ((Bool) -> Void)? { get set }
    func copyToClipboard(_ value: String)
}

final class DeviceInfoViewModel: ObservableObject {
    let userSession: UserSession
    let uuid: String
    let addedDate: String
    let proteusID: String
    let getUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol
    let userClient: UserClient
    var isE2EIdentityEnabled: Bool
    var isSelfClient: Bool
    var title: String
    var certificateStatus: E2EIdentityCertificateStatus {
        guard let certificate = e2eIdentityCertificate,
                let status = E2EIdentityCertificateStatus.allCases.filter({
                        $0.titleForStatus() == certificate.certificateStatus
                    }
                ).first
        else {
            return isE2EIdentityEnabled ? .notActivated : .none
        }
        return status
    }
    var isCertificateExpiringSoon: Bool {
        guard let certificate = e2eIdentityCertificate else {
            return false
        }
        return certificate.expiryDate < Date.now + .oneDay + .oneDay
    }
    @Published var e2eIdentityCertificate: E2eIdentityCertificate?
    private var actionsHandler: any DeviceDetailsViewActions
    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }
    @Published var isRemoved: Bool = false
    @Published var isReset: Bool = false
    @Published var isProteusVerificationEnabled: Bool = false
    @Published var isActionInProgress: Bool = false
    @Published var proteusKeyFingerprint: String

    init(
        uuid: String,
        title: String,
        addedDate: String,
        proteusKeyFingerprint: String,
        proteusID: String,
        isProteusVerificationEnabled: Bool,
        actionsHandler: any DeviceDetailsViewActions,
        isE2EIdentityEnabled: Bool,
        isSelfClient: Bool,
        userSession: UserSession,
        getUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol,
        userClient: UserClient
    ) {
        self.uuid = uuid
        self.title = title
        self.addedDate = addedDate
        self.proteusKeyFingerprint = proteusKeyFingerprint
        self.proteusID = proteusID
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
        self.userSession = userSession
        self.isSelfClient = isSelfClient
        self.getUserClientFingerprintUseCase = getUserClientFingerprintUseCase
        self.userClient = userClient
        self.actionsHandler.isProcessing = {[weak self] isProcessing in
            RunLoop.main.perform {
                self?.isActionInProgress = isProcessing
            }
        }
    }

    func fetchFingerPrintForProteus() async {
        isActionInProgress = true
        guard let data = await getUserClientFingerprintUseCase.invoke(userClient: userClient), let fingerPrint = String(data: data, encoding: .utf8) else {
            return
        }
        self.proteusKeyFingerprint = fingerPrint.splitStringIntoLines(charactersPerLine: 16).uppercased()
        isActionInProgress = false
    }

    func fetchE2eCertificate() async {
        isActionInProgress = true
        e2eIdentityCertificate = await actionsHandler.fetchCertificate()
        isActionInProgress = false
    }

    func removeDevice() async {
        isActionInProgress = true
        isRemoved = await actionsHandler.removeDevice()
        isActionInProgress = false
    }

    func resetSession() async {
        isActionInProgress = true
        isReset = await actionsHandler.resetSession()
        isActionInProgress = false
    }

    func updateVerifiedStatus(_ value: Bool) async {
        let result = await actionsHandler.updateVerified(value)
        self.isProteusVerificationEnabled = result
    }

    func copyToClipboard(_ value: String) {
        actionsHandler.copyToClipboard(value)
    }
}

extension DeviceInfoViewModel: Identifiable {
    var id: String {
        return uuid
    }
}

extension DeviceInfoViewModel {
    static func map(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        getUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol
    ) -> DeviceInfoViewModel {
        return DeviceInfoViewModel(
            uuid: UUID().uuidString,
            title: userClient.model ?? "",
            addedDate: userClient.activationDate?.formattedDate ?? "",
            proteusKeyFingerprint: "",
            proteusID: userClient.proteusSessionID?.clientID.fingerprintStringWithSpaces.uppercased() ?? "",
            isProteusVerificationEnabled: userClient.user?.isVerified ?? false,
            actionsHandler: DeviceDetailsViewActionsHandler(
                userClient: userClient,
                userSession: userSession,
                credentials: credentials
            ),
            isE2EIdentityEnabled: DeveloperDeviceDetailsSettingsSelectionViewModel.isE2eIdentityViewEnabled,
            isSelfClient: userClient.isSelfClient(),
            userSession: userSession,
            getUserClientFingerprintUseCase: getUserClientFingerprintUseCase,
            userClient: userClient
        )
    }
}
