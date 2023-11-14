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
    @Binding var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPresented: Bool
    var body: some View {
            if viewModel.e2eIdentityCertificate.certificate.isEmpty {
                SwiftUI.Button {
                    Task {
                        await viewModel.actionsHandler.fetchCertificate()
                    }
                } label: {
                    Text(L10n.Localizable.Device.Details.Get.certificate)
                        .foregroundStyle(.black)
                        .font(UIFont.normalRegularFont.swiftUIfont.bold())
                }
            } else {
                if viewModel.e2eIdentityCertificate.isExpiringSoon {
                    SwiftUI.Button {
                        Task {
                            await viewModel.actionsHandler.fetchCertificate()
                        }
                    } label: {
                        Text(L10n.Localizable.Device.Details.Update.certificate)
                            .foregroundStyle(.black)
                            .font(UIFont.normalRegularFont.swiftUIfont.bold())
                    }
                }
                Divider()
                SwiftUI.Button(action: {
                    viewModel.actionsHandler.showCertificate {
                        return viewModel.e2eIdentityCertificate.isValidCertificate
                    } result: { isValid in
                        if isValid {
                            isCertificateViewPresented.toggle()
                        }
                    }
                }, label: {
                    HStack {
                        Text(L10n.Localizable.Device.Details.Show.Certificate.details)
                            .foregroundStyle(.black)
                            .font(UIFont.normalRegularFont.swiftUIfont.bold())

                        Spacer()
                        Image(.rightArrow)

                    }.padding()
                })
            }
    }
}

#Preview {
    DeviceDetailsButtonsView(
        viewModel: .constant(
            DeviceInfoViewModel(
                    udid: "123g4",
                    title: "Device 4",
                    mlsThumbprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
""",
                    deviceKeyFingerprint:
"""
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""",
                    proteusID: "skjdabfnkscjka",
                    isProteusVerificationEnabled: false,
                    e2eIdentityCertificate:
                        E2EIdentityCertificate(
                            status: .notActivated,
                            serialNumber:
"""
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""",

                            certificate: .random(
                                length: 1000
                            ),
                            exipirationDate: .now + .fourWeeks
                        )
            )
        ),
        isCertificateViewPresented: .constant(
            false
        )
    )
}
