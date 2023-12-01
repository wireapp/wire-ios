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
import Combine

struct DeviceDetailsView: View {
    @Environment(\.dismiss)
    private var dismiss

    @StateObject var viewModel: DeviceInfoViewModel
    @State var isCertificateViewPresented: Bool = false

    var dismissedView: (() -> Void)?

    var e2eIdentityCertificateView: some View {
        VStack(alignment: .leading) {
            DeviceDetailsE2EIdentityCertificateView(
                viewModel: viewModel,
                isCertificateViewPreseneted: $isCertificateViewPresented
            )
            .padding(.leading, 16)

            DeviceDetailsButtonsView(
                viewModel: viewModel,
                isCertificateViewPresented: $isCertificateViewPresented
            )
        }
        .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
        .padding(.top, 8)
    }

    var proteusView: some View {
        VStack(
            alignment: .leading
        ) {
            Text(L10n.Localizable.Device.Details.Section.Proteus.title)
                .font(UIFont.mediumRegular.swiftUIFont)
                .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
                .frame(height: 28)
                .padding([.leading, .top], 16)
            DeviceDetailsProteusView(viewModel: viewModel, isVerfied: viewModel.isProteusVerificationEnabled)
                .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
            if viewModel.isSelfClient {
                Text(L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle)
                    .font(.footnote)
                    .padding([.leading, .trailing], 16)
                    .padding([.top, .bottom], 8)
            } else {
                DeviceDetailsBottomView(viewModel: viewModel)
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isE2EIdentityEnabled {
                    e2eIdentityCertificateView
                }
                proteusView
            }
            .background(SemanticColors.View.backgroundDefault.swiftUIColor)
            .environment(
                \.defaultMinListHeaderHeight,
                 10
            )
            .listStyle(.plain)
            .overlay(content: {
                if viewModel.isActionInProgress {
                    SwiftUI.ProgressView()
                }
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button(
                        action: {
                            dismiss()
                        },
                        label: {
                            Image(.backArrow)
                                .renderingMode(.template)
                                .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
                        }
                    )
                }
                ToolbarItem(placement: .principal) {
                    DeviceView(viewModel: viewModel).titleView
                }

            }
        }

        .background(SemanticColors.View.backgroundDefault.swiftUIColor)
        .sheet(isPresented: $isCertificateViewPresented) {

        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.fetchFingerPrintForProteus()
                await viewModel.fetchE2eCertificate()
            }
        }
        .onDisappear {
            dismissedView?()
        }
    }
}
