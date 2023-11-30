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

struct DeviceDetailsButtonsView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPresented: Bool

    var getCertificateButton: some View {
        SwiftUI.Button {
            Task {
                await viewModel.fetchE2eCertificate()
            }
        } label: {
            Text(L10n.Localizable.Device.Details.Section.E2e.getcertificate)
            .foregroundStyle(SemanticColors.Label.textDefault.swiftUIColor)
            .font(UIFont.normalRegularFont.swiftUIFont.bold())
        }
    }

    var updateCertificateButton: some View {
        SwiftUI.Button {
            Task {
                await viewModel.fetchE2eCertificate()
            }
        } label: {
            VStack(alignment: .leading) {
                Text(L10n.Localizable.Device.Details.Section.E2e.updatecertificate)
                    .foregroundStyle(SemanticColors.Label.textDefault.swiftUIColor)
                    .font(UIFont.normalRegularFont.swiftUIFont.bold())
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
                    Text(L10n.Localizable.Device.Details.Section.E2e.showcertificatedetails)
                        .foregroundStyle(SemanticColors.Label.textDefault.swiftUIColor)
                        .font(UIFont.normalRegularFont.swiftUIFont.bold())
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
            Divider()
        case .expired:
            Divider()
            updateCertificateButton.padding()
            showCertificateButton.padding()
        default:
            Divider()
            getCertificateButton.padding()
        }
        Divider()
    }
}
