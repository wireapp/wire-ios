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

struct DeviceDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var viewModel: DeviceInfoViewModel
    @State var isCertificateViewPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                if !viewModel.mlsThumbprint.isEmpty {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 0) {
                            Text(L10n.Localizable.Device.Details.Section.mls)
                        }
                        .padding(.bottom, 8)
                        .padding([.top, .leading], 16)
                        .frame(maxWidth: .infinity, maxHeight: 42, alignment: .leading)
                        .background(Color(red: 0.93, green: 0.94, blue: 0.94))

                        DeviceMLSView(viewModel: $viewModel).padding(.leading, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .padding(.trailing, 16)
                            .background(Color.white)
                    }

                            if viewModel.e2eIdentityCertificate.status != .none {
                                    VStack(alignment: .leading) {
                                        DeviceDetailsE2EIdentityCertificateView(viewModel: $viewModel, isCertificateViewPreseneted: $isCertificateViewPresented).padding(.leading, 16)

                                DeviceDetailsButtonsView(viewModel: $viewModel, isCertificateViewPresented: $isCertificateViewPresented)
                            }.background(Color.white)
                                    .padding(.top, 8)
                        }

                }

                VStack(alignment: .leading) {
                    Text(L10n.Localizable.Device.Details.Section.proteus)
                        .frame(height: 45)
                        .padding(.leading, 16)
                    DeviceDetailsProteusView(viewModel: $viewModel)
                    DeviceDetailsBottomView(viewModel: $viewModel)

                }
            }
            .background(Color.backgroundColor)
            .environment(\.defaultMinListHeaderHeight, 10)
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button(action: {
                        dismiss()
                    }, label: {
                        Image(.backArrow)
                    })
                }
                ToolbarItem(placement: .principal) {
                    DeviceView(viewModel: viewModel).titleView
                }
            })
        }
        .background(Color.backgroundColor)
        .sheet(isPresented: $isCertificateViewPresented,
                onDismiss: didDismiss) {
            CertificateDetailsView(
                certificateDetails: viewModel.e2eIdentityCertificate.certificate,
                isMenuPresented: isCertificateViewPresented,
                performDownload: {
                    Task {
                        await viewModel.actionsHandler.fetchCertificate()
                    }
                }, performCopy: { value in
                    viewModel.actionsHandler.copyToClipboard(value)
                }

            )
                .toolbar {
                    SwiftUI.Image(.attention).onTapGesture {
                        isCertificateViewPresented.toggle()
                    }
                }
         }
        .navigationBarBackButtonHidden(true)
    }

    func didDismiss() {
    }
}

#Preview {
    DeviceDetailsView(
        viewModel: .constant( DeviceInfoViewModel(
            udid: "123g4",
            title: "Device 4",
            mlsThumbprint: """
3d c8 7f ff 07 c9 29 6e
3d c8 7f ff 07 c9 29 6e
65 68 7f ff 07 c9 29 6e
3d c8 7f ff 07 c9 65 6f
""",
            deviceKeyFingerprint: """
ff 25 d7 13 f3 18 84 7a
a5 4c 44 32 47 7c a0 b2
c2 b3 f9 8c 87 17 f6 9b
e8 f9 8c 87 17 f6 9b e8
""",
            proteusID: "3D C8 7F FF 07 C9 29 6E",
            isProteusVerificationEnabled: true,
            e2eIdentityCertificate: E2EIdentityCertificate(
                status: .revoked,
                serialNumber: """
e5:d5:e6:75:7e:04:86:07:
14:3c:a0:ed:9a:8d:e4:fd
""",
                certificate: .random(
                    length: 1000
                ),
                exipirationDate: .now + .fourWeeks
            )
            )
        ),
        isCertificateViewPresented: false
    )

}
