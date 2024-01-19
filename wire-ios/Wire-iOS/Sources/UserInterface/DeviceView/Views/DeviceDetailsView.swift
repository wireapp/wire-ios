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
import WireCommonComponents

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
            .padding(.leading, ViewConstants.Padding.standard)

            DeviceDetailsButtonsView(
                viewModel: viewModel,
                isCertificateViewPresented: $isCertificateViewPresented
            )
        }
        .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
        .padding(.top, ViewConstants.Padding.medium)
    }

    var proteusView: some View {
        VStack(alignment: .leading) {
            sectionTitleView(title: L10n.Localizable.Device.Details.Section.Proteus.title)
            DeviceDetailsProteusView(viewModel: viewModel, isVerfied: viewModel.isProteusVerificationEnabled)
                .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
            if viewModel.isSelfClient {
                Text(L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle)
                    .font(.footnote)
                    .padding([.leading, .trailing], ViewConstants.Padding.standard)
                    .padding([.top, .bottom], ViewConstants.Padding.medium)
            } else {
                DeviceDetailsBottomView(viewModel: viewModel)
            }
        }
    }

    var mlsView: some View {
        VStack(alignment: .leading) {
            sectionTitleView(title: L10n.Localizable.Device.Details.Section.Mls.signature.uppercased())
            DeviceMLSView(viewModel: viewModel)
                .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if let thumbprint = viewModel.mlsThumbprint, thumbprint.isNonEmpty {
                    mlsView
                    if viewModel.isE2eIdentityEnabled {
                        e2eIdentityCertificateView
                    }
                }
                proteusView
            }
            .background(SemanticColors.View.backgroundDefault.swiftUIColor)
            .environment(\.defaultMinListHeaderHeight, ViewConstants.Header.Height.minimum)
            .listStyle(.plain)
            .overlay(
                content: {
                        if viewModel.isActionInProgress {
                            SwiftUI.ProgressView()
                        }
                    }
            )
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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            dismissedView?()
        }
        .onReceive(viewModel.$isRemoved) { isRemoved in
            if isRemoved {
                dismiss()
            }
        }
        .sheet(isPresented: $isCertificateViewPresented) {
            if let certificate = viewModel.e2eIdentityCertificate {
                E2EIdentityCertificateDetailsView(
                    certificateDetails: certificate.details.uppercased(),
                    isDownloadAndCopyEnabled: viewModel.isCopyEnabled,
                    isMenuPresented: false,
                    performDownload: viewModel.downloadE2EIdentityCertificate,
                    performCopy: viewModel.copyToClipboard
                )
            }
        }
    }

    @ViewBuilder
    func sectionTitleView(title: String) -> some View {
        Text(title)
            .font(FontSpec.mediumRegularFont.swiftUIFont)
            .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
            .frame(height: ViewConstants.View.Height.small)
            .padding([.leading, .top], ViewConstants.Padding.standard)
    }
}
