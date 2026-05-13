//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

struct SuccessfulCertificateEnrollmentViewModel {

    enum Mode {
        case enroll
        case update
    }

    enum Image: Equatable {
        case certificateValid
    }

    struct DisplayState {
        let title: String
        let subtitle: String
        let certificateDetailsButtonTitle: String
        let confirmationButtonTitle: String
        let image: Image
    }

    struct CertificateDetailsState {
        let certificateDetails: String
        let isDownloadAndCopyEnabled: Bool
        let fileName: String
        let fileType: String
    }

    enum Route {
        case certificateDetails(CertificateDetailsState)
        case complete
    }

    private typealias LocalizedEnrollE2eiCertificate = L10n.Localizable.EnrollE2eiCertificate
    private typealias LocalizedUpdateE2eiCertificate = L10n.Localizable.UpdateE2eiCertificate

    var certificateDetails: String

    private let mode: Mode

    init(mode: Mode, certificateDetails: String = "") {
        self.mode = mode
        self.certificateDetails = certificateDetails
    }

    var displayState: DisplayState {
        .init(
            title: mode == .update ? LocalizedUpdateE2eiCertificate.title : LocalizedEnrollE2eiCertificate.title,
            subtitle: mode == .update ? LocalizedUpdateE2eiCertificate.subtitle : LocalizedEnrollE2eiCertificate.subtitle,
            certificateDetailsButtonTitle: LocalizedEnrollE2eiCertificate.certificateDetailsButton,
            confirmationButtonTitle: LocalizedEnrollE2eiCertificate.okButton,
            image: .certificateValid
        )
    }

    func certificateDetailsTapped() -> Route {
        .certificateDetails(
            .init(
                certificateDetails: certificateDetails,
                isDownloadAndCopyEnabled: Settings.isClipboardEnabled,
                fileName: "certificate-chain",
                fileType: "txt"
            )
        )
    }

    func confirmationTapped() -> Route {
        .complete
    }

}
