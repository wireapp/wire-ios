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
                .font(FontSpec.headerSemiboldFont.swiftUIFont)
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
                            .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
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
                .font(FontSpec.smallFont.swiftUIFont.monospaced())
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
                    .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
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
                    .font(FontSpec.normalBoldFont.swiftUIFont)
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
                    .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
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
                    .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
            }
        )
    }

    private var bottomBarView: some View {
        VStack {
            if isDownloadAndCopyEnabled {
                HStack {
                    downloadImageButton.padding()
                    downloadButton
                        .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
                        .padding()
                    Spacer()
                    moreButton
                        .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
                    .confirmationDialog("...", isPresented: $isMenuPresented) {
                        copyToClipboardButton
                            .foregroundColor(SemanticColors.Icon.foregroundDefaultBlack.swiftUIColor)
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
                    .foregroundColor(SemanticColors.View.backgroundSeparatorCell.swiftUIColor)
            }
        }
    }

    var body: some View {

        titleView
            .background(SemanticColors.View.backgroundDefault.swiftUIColor)
        certificateView
            .background(SemanticColors.View.backgroundDefaultWhite.swiftUIColor)

        .safeAreaInset(edge: .bottom,
                       spacing: .zero) {
            bottomBarView.background(SemanticColors.View.backgroundUserCell.swiftUIColor)
        }
        .ignoresSafeArea()
        .background(SemanticColors.View.backgroundDefault.swiftUIColor)
    }
}
