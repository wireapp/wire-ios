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

struct ProfileDeviceDetailsView: View {
    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject var viewModel: DeviceInfoViewModel
    @State private var isCertificateViewPresented: Bool = false
    @State private var isDebugViewPresented: Bool = false

    private let onDisappear: (() -> Void)?

    init(viewModel: DeviceInfoViewModel, onDisappear: (() -> Void)?) {
        self.viewModel = viewModel
        self.onDisappear = onDisappear
    }

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
        .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
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
            .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)

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
            sectionTitleView(title: L10n.Localizable.Device.Details.Section.Mls.signature.uppercased())

            DeviceMLSView(viewModel: viewModel)
                .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var showDeviceFingerPrintView: some View {
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.onShowMyDeviceTapped()
                }
            } label: {
                Text(L10n.Localizable.Profile.Devices.Detail.ShowMyDevice.title)
                .padding(.all, ViewConstants.Padding.standard)
                .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
                .font(UIFont.swiftUIFont(for: .bodyTwoSemibold))
            }
            Spacer()
            Asset.Images.chevronRight.swiftUIImage.padding(.trailing, ViewConstants.Padding.standard)
        }
        .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isE2eIdentityEnabled {
                    if let thumbprint = viewModel.mlsThumbprint, thumbprint.isNonEmpty {
                        mlsView
                    }

                    e2eIdentityCertificateView
                }

                proteusView
            }
            .background(SemanticColors.View.backgroundDefault.swiftUIColor)
            .environment(\.defaultMinListHeaderHeight, ViewConstants.Header.Height.minimum)
            .listStyle(.plain)
            .overlay(
                content: {
                    VStack {
                        if viewModel.isActionInProgress {
                            Spacer()
                            SwiftUI.ProgressView()
                        }
                        Spacer()
                        showDeviceFingerPrintView
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button(
                        action: {
                            isDebugViewPresented.toggle()
                        },
                        label: {
                            if viewModel.showDebugMenu {
                                Text("Debug")
                            }
                        }
                    )
                }
            }
        }
        .navigationViewStyle(.stack)
        .background(SemanticColors.View.backgroundDefault.swiftUIColor)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            onDisappear?()
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
        .alert("Debug options", isPresented: $isDebugViewPresented, actions: {
            SwiftUI.Button("Delete Device", action: {
                  viewModel.onDeleteDeviceTapped()
              })
            SwiftUI.Button("Duplicate Session", action: {
                  viewModel.onDuplicateClientTapped()
              })
            SwiftUI.Button("Corrupt Session", action: {
                viewModel.onCorruptSessionTapped()
            })
            SwiftUI.Button("Cancel", role: .cancel, action: {
                isDebugViewPresented.toggle()
            })
            }, message: {
              Text("Tap to perform an action")
            })
    }

    @ViewBuilder
    func sectionTitleView(title: String, description: String? = nil) -> some View {
        Text(title)
            .font(FontSpec.mediumRegularFont.swiftUIFont)
            .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
            .padding([.leading, .top, .trailing], ViewConstants.Padding.standard)

        if let description = description {
            VStack(alignment: .leading) {
                Text(description)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(UIFont.swiftUIFont(for: .subheadline))
                    .foregroundColor(SemanticColors.Label.textCellSubtitle.swiftUIColor)
                    .frame(height: ViewConstants.View.Height.small)
                    .padding([.leading, .top, .trailing], ViewConstants.Padding.standard)
                Text(L10n.Localizable.Profile.Devices.Detail.VerifyMessage.link)
                    .underline()
                    .font(UIFont.swiftUIFont(for: .subheadline).bold())
                    .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
                    .padding(.leading)
                    .onTapGesture {
                        viewModel.onHowToDoThatTapped()
                    }
            }
        }
    }
}
