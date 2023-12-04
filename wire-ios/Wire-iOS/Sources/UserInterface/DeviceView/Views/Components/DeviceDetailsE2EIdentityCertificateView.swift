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

import SwiftUI

struct DeviceDetailsE2EIdentityCertificateView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPreseneted: Bool

    var body: some View {
        Text(L10n.Localizable.Device.Details.Section.E2e.title)
            .font(UIFont.normalSemiboldFont.swiftUIFont)
            .multilineTextAlignment(.leading)
            .padding([.top, .bottom], 16)
        HStack {
            switch viewModel.certificateStatus {
            case .notActivated:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.Label.textCertificateInvalid.swiftUIColor,
                    image: Image(.certificateExpired)
                )
            case .revoked:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.Label.textCertificateInvalid.swiftUIColor,
                    image: Image(.certificateRevoked)
                )
            case .expired:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.Label.textCertificateInvalid.swiftUIColor,
                    image: Image(.certificateExpired)
                )
            case .valid:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.Label.textCertificateValid.swiftUIColor,
                    image: Image(.certificateValid)
                )
            case .none:
                Spacer()
            }
            Spacer()
        }
        if viewModel.isValidCerificate, let certificate = viewModel.e2eIdentityCertificate {
            Text(L10n.Localizable.Device.Details.Section.E2e.serialnumber)
                .font(UIFont.smallSemiboldFont.swiftUIFont)
                .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
                .padding(.top, 8)
                .padding(.bottom, 4)
            Text(
                certificate.serialNumber
                    .uppercased()
                    .splitStringIntoLines(charactersPerLine: 16)
                    .replacingOccurrences(of: "  ", with: ":")
            )
            .font(UIFont.normalRegularFont.monospaced().swiftUIFont)
        }
    }

    @ViewBuilder
    func viewForStatus(
        titleText: String,
        statusText: String,
        textColor: Color,
        image: Image
    ) -> some View {
        Text(titleText)
            .font(UIFont.mediumSemiboldFont.swiftUIFont)
            .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
            .multilineTextAlignment(.leading)
        Text(statusText)
            .foregroundColor(textColor)
            .font(UIFont.normalMediumFont.swiftUIFont)
        image
    }
}
