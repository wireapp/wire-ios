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
    var isE2eIdentityEnabled: Bool { get }
    var shouldUpdateCertificate: Bool { get }
    var isSelfClient: Bool { get }
    var isProcessing: ((Bool) -> Void)? { get set }

    func fetchCertificate() async -> E2eIdentityCertificate?
    func removeDevice() async -> Bool
    func resetSession()
    func updateVerified(_ value: Bool) async -> Bool
    func copyToClipboard(_ value: String)
    func downloadE2EIdentityCertificate()
}

final class DeviceInfoViewModel: ObservableObject {
    let userSession: UserSession
    let addedDate: String
    let proteusID: String
    let getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol
    let userClient: UserClient
    var title: String

    var isSelfClient: Bool

    var isE2EIdentityEnabled: Bool {
        actionsHandler.isE2eIdentityEnabled
    }

    var isValidCerificate: Bool {
        guard let certificate = e2eIdentityCertificate,
                certificate.status != .notActivated,
                certificate.status != .revoked else {
            return false
        }
        return true
    }

    var certificateStatus: E2EIdentityCertificateStatus {
        guard let certificate = e2eIdentityCertificate
        else {
            return .notActivated
        }
        return certificate.status
    }

    var isCertificateExpiringSoon: Bool {
        return actionsHandler.shouldUpdateCertificate
    }

    var mlsThumbprint: String {
        guard let certificate = e2eIdentityCertificate else {
            return ""
        }
        return certificate.mlsThumbprint
    }

    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }

    @Published var e2eIdentityCertificate: E2eIdentityCertificate?
    @Published var isRemoved: Bool = false
    @Published var isReset: Bool = false
    @Published var isProteusVerificationEnabled: Bool = false
    @Published var isActionInProgress: Bool = false
    @Published var proteusKeyFingerprint: String = ""
    @Published var shouldDissmissView: Bool = false

    private var actionsHandler: any DeviceDetailsViewActions

    init(
        title: String,
        addedDate: String,
        proteusID: String,
        isProteusVerificationEnabled: Bool,
        actionsHandler: any DeviceDetailsViewActions,
        userSession: UserSession,
        getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol,
        userClient: UserClient,
        isSelfClient: Bool
    ) {
        self.title = title
        self.addedDate = addedDate
        self.proteusID = proteusID
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.userSession = userSession
        self.getUserClientFingerprint = getUserClientFingerprint
        self.userClient = userClient
        self.isSelfClient = isSelfClient
        self.actionsHandler.isProcessing = {[weak self] isProcessing in
            self?.isActionInProgress = isProcessing
        }
    }

    @MainActor
    func fetchFingerPrintForProteus() async {
        isActionInProgress = true
        guard let data = await getUserClientFingerprint.invoke(userClient: userClient),
                let fingerPrint = String(data: data, encoding: .utf8) else {
            return
        }
        proteusKeyFingerprint = fingerPrint.splitStringIntoLines(charactersPerLine: 16).uppercased()
        isActionInProgress = false
    }

    @MainActor
    func fetchE2eCertificate() async {
        isActionInProgress = true
        let certificate = await actionsHandler.fetchCertificate()
        e2eIdentityCertificate = certificate
        isActionInProgress = false
    }

    @MainActor
    func removeDevice() async {
        let isRemoved = await actionsHandler.removeDevice()
        shouldDissmissView = isRemoved
    }

    func resetSession() {
        actionsHandler.resetSession()
    }

    @MainActor
    func updateVerifiedStatus(_ value: Bool) async {
        let isVerified = await actionsHandler.updateVerified(value)
        isProteusVerificationEnabled = isVerified
    }

    func copyToClipboard(_ value: String) {
        actionsHandler.copyToClipboard(value)
    }

    func downloadE2EIdentityCertificate() {
        actionsHandler.downloadE2EIdentityCertificate()
    }
}

extension DeviceInfoViewModel {
    static func map(
        userClient: UserClient,
        isSelfClient: Bool,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        getUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol,
        e2eIdentityProvider: E2eIdentityProviding
    ) -> DeviceInfoViewModel {
        return DeviceInfoViewModel(
            title: userClient.model ?? "",
            addedDate: userClient.activationDate?.formattedDate ?? "",
            proteusID: userClient.proteusSessionID?.clientID.fingerprintStringWithSpaces.uppercased() ?? "",
            isProteusVerificationEnabled: userClient.verified,
            actionsHandler: DeviceDetailsViewActionsHandler(
                userClient: userClient,
                userSession: userSession,
                credentials: credentials,
                e2eIdentityProvider: e2eIdentityProvider,
                downloadFileManager: DownloadFileManager(
                    documentInteractionController: UIDocumentInteractionController(),
                    logger: WireLogger.e2ei
                )
            ),
            userSession: userSession,
            getUserClientFingerprint: getUserClientFingerprintUseCase,
            userClient: userClient,
            isSelfClient: isSelfClient
        )
    }
}

extension E2EIdentityCertificateStatus {
    typealias Status = L10n.Localizable.Device.Details.Section.E2ei.Status

    func titleForStatus() -> String {
        switch self {
        case .notActivated:
            return Status.notActivated
        case .revoked:
            return Status.revoked
        case .expired:
            return Status.expired
        case .valid:
            return Status.valid
        }
    }

    func imageForStatus() -> Image? {
        switch self {
        case .notActivated:
            return Asset.Images.certificateExpired.swiftUIImage
        case .revoked:
            return Asset.Images.certificateRevoked.swiftUIImage
        case .expired:
            return  Asset.Images.certificateExpired.swiftUIImage
        case .valid:
            return Asset.Images.certificateValid.swiftUIImage
        }
    }

    static func status(for string: String) -> E2EIdentityCertificateStatus? {
        E2EIdentityCertificateStatus.allCases.filter({
            $0.titleForStatus() == string
        }).first
    }
}
