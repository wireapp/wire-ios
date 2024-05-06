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

struct E2EIdentityCertificateDetailsView: View {
    @Environment(\.dismiss)
    private var dismiss
    var certificateDetails: String
    var isDownloadAndCopyEnabled: Bool

    @State var isMenuPresented: Bool

    var performDownload: (() -> Void)?

    var performCopy: ((String) -> Void)?
    var didDismiss: (() -> Void)?

    private var titleView: some View {
        HStack {
            Spacer()
            Text(L10n.Localizable.Device.Details.CertificateDetails.title)
                .font(.textStyle(.h3))
                .accessibilityIdentifier("CertificateDetailsTitle")
            Spacer()
        }
        .padding(.all, ViewConstants.Padding.standard)
        .overlay {
            HStack {
                Spacer()
                SwiftUI.Button(
                    action: {
                        dismiss()
                        didDismiss?()
                    },
                    label: {
                        Image(.close)
                            .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
                    }
                )
                .accessibilityIdentifier("CloseButton")
                .padding(.all, ViewConstants.Padding.standard)
            }
        }
    }

    private var certificateView: some View {
        ScrollView {
            Text(certificateDetails)
                .font(.textStyle(.subline1).monospaced())
                .padding()
                .frame(maxHeight: .infinity)
                .accessibilityIdentifier("CertificateDetailsView")
        }
    }

    private var downloadImageButton: some View {
        SwiftUI.Button(
            action: {
                performDownload?()
            },
            label: {
                Image(.download)
                    .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
            }
        )
    }

    private var downloadButton: some View {
        SwiftUI.Button(
            action: {
                performDownload?()
            },
            label: {
                Text(L10n.Localizable.Content.Message.download)
                    .font(.textStyle(.body2))
            }
        )
        .accessibilityIdentifier("DownloadButton")
    }

    private var moreButton: some View {
        SwiftUI.Button(
            action: {
                isMenuPresented.toggle()
            },
            label: {
                Image(.more)
                    .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
                    .padding(.trailing, ViewConstants.Padding.standard)
            }
        )
        .accessibilityIdentifier("MoreButton")
    }

    private var copyToClipboardButton: some View {
        SwiftUI.Button(
            action: {
                performCopy?(certificateDetails)
            },
            label: {
                Text(L10n.Localizable.Device.Details.CertificateDetails.copyToClipboard)
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
            }
        )
    }

    private var bottomBarView: some View {
        VStack {
            if isDownloadAndCopyEnabled {
                HStack {
                    downloadImageButton.padding()
                    downloadButton
                        .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
                        .padding()
                    Spacer()
                    moreButton
                        .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
                    .confirmationDialog("...", isPresented: $isMenuPresented) {
                        copyToClipboardButton
                            .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        // The background will extend automatically to the edge
        .overlay(alignment: .top) {
            if isDownloadAndCopyEnabled {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(uiColor: SemanticColors.View.backgroundSeparatorCell))
            }
        }
    }

    var body: some View {

        titleView
            .background(Color(uiColor: SemanticColors.View.backgroundDefault))

        certificateView
            .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))

        .safeAreaInset(edge: .bottom,
                       spacing: .zero) {
            bottomBarView.background(Color(uiColor: SemanticColors.View.backgroundUserCell))
        }
        .ignoresSafeArea()
        .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
    }
}

#Preview {
    E2EIdentityCertificateDetailsView(
        certificateDetails: "Sample Certificate Details Here...",
        isDownloadAndCopyEnabled: true,
        isMenuPresented: false
    )
}
