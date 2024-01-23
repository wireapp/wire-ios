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
import WireCommonComponents

struct DeviceDetailsE2EIdentityCertificateView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPreseneted: Bool

    var body: some View {
        Text(L10n.Localizable.Device.Details.Section.E2ei.title)
            .font(FontSpec.normalSemiboldFont.swiftUIFont)
            .multilineTextAlignment(.leading)
            .padding([.top, .bottom], ViewConstants.Padding.standard)
        HStack {
            if let status = viewModel.e2eIdentityCertificate?.status {
                switch status {
                case .notActivated:
                    viewForStatus(
                        statusText: status.title,
                        textColor: SemanticColors.Label.textCertificateInvalid.swiftUIColor,
                        image: status.image
                    )
                case .revoked:
                    viewForStatus(
                        statusText: status.title,
                        textColor: SemanticColors.Label.textCertificateInvalid.swiftUIColor,
                        image: status.image
                    )
                case .expired:
                    viewForStatus(
                        statusText: status.title,
                        textColor: SemanticColors.Label.textCertificateInvalid.swiftUIColor,
                        image: status.image
                    )
                case .valid:
                    viewForStatus(
                        titleText: L10n.Localizable.Device.Details.Section.E2ei.Status.title,
                        statusText: status.title,
                        textColor: SemanticColors.Label.textCertificateValid.swiftUIColor,
                        image: status.image
                    )
                }
            }
            Spacer()
        }
        if let certificate = viewModel.e2eIdentityCertificate, certificate.status != .notActivated {
            Text(L10n.Localizable.Device.Details.Section.E2ei.serialNumber)
                .font(FontSpec.smallSemiboldFont.swiftUIFont)
                .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
                .padding(.top, ViewConstants.Padding.medium)
                .padding(.bottom, ViewConstants.Padding.small)
            Text(
                certificate.serialNumber
                    .splitStringIntoLines(charactersPerLine: 16)
                    .replacingOccurrences(of: " ", with: ":")
            )
            .font(FontSpec.normalRegularFont.swiftUIFont.monospaced())
        }
    }

    @ViewBuilder
    func viewForStatus(
        titleText: String = L10n.Localizable.Device.Details.Section.E2ei.Status.title,
        statusText: String,
        textColor: Color,
        image: Image?
    ) -> some View {
        Text(titleText)
            .font(FontSpec.mediumSemiboldFont.swiftUIFont)
            .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
            .multilineTextAlignment(.leading)
        Text(statusText)
            .foregroundColor(textColor)
            .font(FontSpec.normalMediumFont.swiftUIFont)
        image
    }
}
