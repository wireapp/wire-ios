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

struct DeviceDetailsButtonsView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPresented: Bool

    var getCertificateButton: some View {
        SwiftUI.Button {
            Task {
                await viewModel.fetchE2eCertificate()
            }
        } label: {
            Text(L10n.Localizable.Device.Details.Section.E2ei.getCertificate)
            .foregroundStyle(SemanticColors.Label.textDefault.swiftUIColor)
            .font(FontSpec.normalRegularFont.swiftUIFont.bold())
        }
    }

    var updateCertificateButton: some View {
        SwiftUI.Button {
            Task {
                await viewModel.fetchE2eCertificate()
            }
        } label: {
            VStack(alignment: .leading) {
                Text(L10n.Localizable.Device.Details.Section.E2ei.updateCertificate)
                    .foregroundStyle(SemanticColors.Label.textDefault.swiftUIColor)
                    .font(FontSpec.normalRegularFont.swiftUIFont.bold())
            }
        }
    }

    var showCertificateButton: some View {
        SwiftUI.Button(
            action: {
                    isCertificateViewPresented.toggle()
            },
            label: {
                HStack {
                    Text(L10n.Localizable.Device.Details.Section.E2ei.showCertificateDetails)
                        .foregroundStyle(SemanticColors.Label.textDefault.swiftUIColor)
                        .font(FontSpec.normalRegularFont.swiftUIFont.bold())
                    Spacer()
                    Image(.chevronRight)
                        .renderingMode(.template)
                        .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
                }
            }
        )
    }

    var body: some View {
        switch viewModel.certificateStatus {
        case .valid:
            if viewModel.isCertificateExpiringSoon {
                Divider()
                updateCertificateButton.padding()
            }
            Divider()
            showCertificateButton.padding()
        case .notActivated:
            Divider()
            getCertificateButton.padding()
        case .revoked:
            Divider()
            showCertificateButton.padding()
        case .expired:
            Divider()
            updateCertificateButton.padding()
            Divider()
            showCertificateButton.padding()
        case .none:
            Divider()
        }
        Divider()
    }
}
