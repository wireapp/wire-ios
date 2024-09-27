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

// MARK: - OtherUserDeviceDetailsView

struct OtherUserDeviceDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: DeviceInfoViewModel
    @State private var isCertificateViewPresented = false

    private var e2eIdentityCertificateView: some View {
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
        .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
        .padding(.top, ViewConstants.Padding.medium)
        .frame(maxWidth: .infinity)
    }

    private var proteusView: some View {
        VStack(alignment: .leading) {
            let userName = viewModel.userClient.user?.name ?? ""
            sectionTitleView(
                title: L10n.Localizable.Device.Details.Section.Proteus.title,
                description: L10n.Localizable.Profile.Devices.Detail.verifyMessage(userName)
            )

            DeviceDetailsProteusView(
                viewModel: viewModel,
                isVerified: viewModel.isProteusVerificationEnabled,
                shouldShowActivatedDate: false
            )
            .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))

            if viewModel.isSelfClient {
                Text(L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle)
                    .font(.footnote)
                    .padding([.leading, .trailing], ViewConstants.Padding.standard)
                    .padding([.top, .bottom], ViewConstants.Padding.medium)
            } else {
                DeviceDetailsBottomView(viewModel: viewModel, showRemoveDeviceButton: false)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var mlsView: some View {
        VStack(alignment: .leading) {
            sectionTitleView(
                title: L10n.Localizable.Device.Details.Section.Mls
                    .signature(viewModel.mlsCiphersuite?.signature ?? "").uppercased()
            )

            DeviceMLSView(viewModel: viewModel)
                .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
        }
        .frame(maxWidth: .infinity)
    }

    private var showDeviceFingerPrintView: some View {
        HStack {
            Text(L10n.Localizable.Profile.Devices.Detail.ShowMyDevice.title)
                .font(.textStyle(.body2))
                .padding(.all, ViewConstants.Padding.standard)
                .foregroundColor(Color(SemanticColors.Label.textDefault))
            Spacer()
            Image(.chevronRight)
                .padding(.trailing, ViewConstants.Padding.standard)
        }
        .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if viewModel.isE2eIdentityEnabled {
                    if let thumbprint = viewModel.mlsThumbprint, !thumbprint.isEmpty {
                        mlsView
                    }
                    e2eIdentityCertificateView
                }
                proteusView
                showDeviceFingerPrintView.onTapGesture {
                    viewModel.onShowMyDeviceTapped()
                }
            }
        }
        .background(Color(uiColor: SemanticColors.View.backgroundDefault))
        .environment(\.defaultMinListHeaderHeight, ViewConstants.Header.Height.minimum)
        .listStyle(.plain)
        .overlay(
            content: {
                VStack {
                    if viewModel.isActionInProgress {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        )
        .background(Color(uiColor: SemanticColors.View.backgroundDefault))
        .onAppear {
            viewModel.onAppear()
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .sheet(isPresented: $isCertificateViewPresented) {
            if let certificate = viewModel.e2eIdentityCertificate {
                E2EIdentityCertificateDetailsView(
                    certificateDetails: certificate.details,
                    isDownloadAndCopyEnabled: viewModel.isCopyEnabled,
                    isMenuPresented: false,
                    performDownload: viewModel.downloadE2EIdentityCertificate,
                    performCopy: viewModel.copyToClipboard
                )
            }
        }
    }

    @ViewBuilder
    func sectionTitleView(title: String, description: String? = nil) -> some View {
        Text(title)
            .font(FontSpec.mediumRegularFont.swiftUIFont)
            .foregroundColor(Color(uiColor: SemanticColors.Label.textSectionHeader))
            .padding([.leading, .top, .trailing], ViewConstants.Padding.standard)

        if let description {
            VStack(alignment: .leading) {
                Text(description)
                    .font(.textStyle(.h4))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color(SemanticColors.Label.textCellSubtitle))
                    .frame(height: ViewConstants.View.Height.small)
                    .padding([.leading, .top, .trailing], ViewConstants.Padding.standard)
                Text(L10n.Localizable.Profile.Devices.Detail.VerifyMessage.link)
                    .underline()
                    .font(.textStyle(.h4))
                    .bold()
                    .foregroundColor(Color(SemanticColors.Label.textDefault))
                    .padding(.leading)
                    .onTapGesture {
                        viewModel.onHowToDoThatTapped()
                    }
            }
        }
    }
}

// MARK: DeviceInfoView

extension OtherUserDeviceDetailsView: DeviceInfoView {}
