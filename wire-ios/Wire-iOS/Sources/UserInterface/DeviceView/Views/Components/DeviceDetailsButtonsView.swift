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

import SwiftUI
import WireCommonComponents
import WireDesign

struct DeviceDetailsButtonsView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPresented: Bool

    var getCertificateButton: some View {
        Button {
            Task {
                await viewModel.enrollClient()
            }
        } label: {
            Text(L10n.Localizable.Device.Details.Section.E2ei.getCertificate)
                .foregroundStyle(Color(uiColor: SemanticColors.Label.textDefault))
                .font(FontSpec.normalRegularFont.swiftUIFont.bold())
        }
    }

    var updateCertificateButton: some View {
        Button {
            Task {
                await viewModel.enrollClient()
            }
        } label: {
            VStack(alignment: .leading) {
                Text(L10n.Localizable.Device.Details.Section.E2ei.updateCertificate)
                    .foregroundStyle(Color(uiColor: SemanticColors.Label.textDefault))
                    .font(FontSpec.normalRegularFont.swiftUIFont.bold())
            }
        }
    }

    var showCertificateButton: some View {
        Button(
            action: {
                isCertificateViewPresented = true
            },
            label: {
                HStack {
                    Text(L10n.Localizable.Device.Details.Section.E2ei.showCertificateDetails)
                        .foregroundStyle(Color(uiColor: SemanticColors.Label.textDefault))
                        .font(FontSpec.normalRegularFont.swiftUIFont.bold())
                    Spacer()
                    Image(.chevronRight)
                        .renderingMode(.template)
                        .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
                }
            }
        )
    }

    var body: some View {
        if let status = viewModel.e2eIdentityCertificate?.status {
            switch status {
            case .valid:
                if viewModel.isSelfClient, viewModel.isCertificateExpiringSoon == true {
                    Divider()
                    updateCertificateButton.padding()
                }
                Divider()
                showCertificateButton.padding()

            case .notActivated:
                if !viewModel.isFromConversation, viewModel.isSelfClient {
                    Divider()
                    getCertificateButton.padding()
                }

            case .invalid,
                 .revoked:
                Divider()
                showCertificateButton.padding()

            case .expired:
                if !viewModel.isFromConversation, viewModel.isSelfClient {
                    Divider()
                    updateCertificateButton.padding()
                }
                Divider()
                showCertificateButton.padding()
            }
        }
        Divider()
    }
}
