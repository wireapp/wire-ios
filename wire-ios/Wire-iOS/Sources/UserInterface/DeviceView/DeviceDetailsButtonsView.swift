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
                SwiftUI.Button("Get Certificate") {
                    Task {
                        await viewModel.actionsHandler.fetchCertificate()
                    }
                }

            } else {
                if viewModel.e2eIdentityCertificate.isExpiringSoon {
                    SwiftUI.Button("Update Certificate") {
                        Task {
                            await viewModel.actionsHandler.fetchCertificate()
                        }
                    }
                }
                Divider()
                SwiftUI.Button(action: {
                    isCertificateViewPresented.toggle()
                }, label: {
                    HStack {
                        Text("Show Certificate Details").foregroundStyle(.black)
                            .font(UIFont.normalRegularFont.swiftUIfont.bold())

                        Spacer()
                        Image(.rightArrow)

                    }.padding()
                })
            }
    }
}
