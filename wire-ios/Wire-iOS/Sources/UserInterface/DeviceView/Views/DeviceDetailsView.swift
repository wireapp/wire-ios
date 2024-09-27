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

import Combine
import SwiftUI
import WireCommonComponents
import WireDesign

// MARK: - DeviceDetailsView

struct DeviceDetailsView: View {
    typealias E2ei = L10n.Localizable.Registration.Signin.E2ei

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private(set) var viewModel: DeviceInfoViewModel
    @State private var isCertificateViewPresented = false
    @State private var didEnrollCertificateFail = false

    @ViewBuilder var e2eIdentityCertificateView: some View {
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

    @ViewBuilder var proteusView: some View {
        VStack(alignment: .leading) {
            sectionTitleView(title: L10n.Localizable.Device.Details.Section.Proteus.title)
            DeviceDetailsProteusView(viewModel: viewModel, isVerified: viewModel.isProteusVerificationEnabled)
                .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
            if viewModel.isSelfClient {
                Text(L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle)
                    .font(.footnote)
                    .padding([.leading, .trailing], ViewConstants.Padding.standard)
                    .padding([.top, .bottom], ViewConstants.Padding.medium)
            } else {
                DeviceDetailsBottomView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder var mlsView: some View {
        VStack(alignment: .leading) {
            sectionTitleView(
                title: L10n.Localizable.Device.Details.Section.Mls
                    .signature(viewModel.mlsCiphersuite?.signature.description ?? "").uppercased()
            )
            DeviceMLSView(viewModel: viewModel)
                .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        ScrollView {
            if viewModel.isE2eIdentityEnabled {
                if let thumbprint = viewModel.mlsThumbprint, !thumbprint.isEmpty {
                    mlsView
                }
                e2eIdentityCertificateView
            }
            proteusView
        }
        .background(Color(uiColor: SemanticColors.View.backgroundDefault))
        .environment(\.defaultMinListHeaderHeight, ViewConstants.Header.Height.minimum)
        .listStyle(.plain)
        .overlay(
            content: {
                if viewModel.isActionInProgress {
                    ProgressView()
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
        .onReceive(viewModel.$showEnrollmentCertificateError, perform: { _ in
            didEnrollCertificateFail = viewModel.showEnrollmentCertificateError
        })
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
        .alert(E2ei.Error.Alert.title, isPresented: $didEnrollCertificateFail) {
            Button(L10n.Localizable.General.ok) {
                didEnrollCertificateFail = false
            }
        }
    }

    @ViewBuilder
    func sectionTitleView(title: String) -> some View {
        Text(title)
            .font(FontSpec.mediumRegularFont.swiftUIFont)
            .foregroundColor(Color(uiColor: SemanticColors.Label.textSectionHeader))
            .frame(height: ViewConstants.View.Height.small)
            .padding([.leading, .top], ViewConstants.Padding.standard)
    }
}

// MARK: DeviceInfoView

extension DeviceDetailsView: DeviceInfoView {}
