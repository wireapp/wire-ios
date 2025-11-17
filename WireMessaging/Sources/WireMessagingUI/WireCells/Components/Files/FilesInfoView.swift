//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDesign

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FilesInfoView: View {

    enum Info: Equatable {
        case preparingFiles
        case noFilesFound(scope: Scope)
        case error

        enum Scope: Equatable {
            case allConversations
            case oneConversation
        }

        var localizedStrings: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                (Strings.Files.PendingCells.title, Strings.Files.PendingCells.message)
            case let .noFilesFound(scope):
                (
                    Strings.Files.NoData.title,
                    scope == .allConversations ? Strings.AllFiles.NoData.message : Strings.Files.NoData.message
                )
            case .error:
                (Strings.Files.Error.title, Strings.Files.Error.message)
            }
        }

        var accessibilityStrings: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                (Accessibility.Files.PendingCells.title, Accessibility.Files.PendingCells.message)
            case let .noFilesFound(scope):
                (
                    Accessibility.Files.NoData.title,
                    scope == .allConversations ? Accessibility.AllFiles.NoData.message : Accessibility.Files.NoData
                        .message
                )
            case .error:
                (Accessibility.Files.Error.title, Accessibility.Files.Error.message)
            }
        }

        var accessibilityIdentifiers: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                ("preparing-files-title", "preparing-files-message")
            case let .noFilesFound(scope):
                (
                    "no-files-title",
                    scope == .allConversations ? "no-files-all-conversations-message" : "no-files-message"
                )
            case .error:
                ("error-title", "error-message")
            }
        }
    }

    let info: Info
    var onReload: (() -> Void)?

    var body: some View {
        VStack(spacing: 25) {
            Text(info.localizedStrings.title)
                .padding([.leading, .trailing], info == .preparingFiles ? 30 : 0)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(SemanticColors.Label.textDefault.color)
                .accessibilityLabel(info.accessibilityStrings.title)
                .accessibilityIdentifier(info.accessibilityIdentifiers.title)

            Text(info.localizedStrings.message)
                .padding([.leading, .trailing], info == .preparingFiles ? 0 : 30)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(SemanticColors.Label.baseSecondaryText.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(info.accessibilityStrings.message)
                .accessibilityIdentifier(info.accessibilityIdentifiers.message)

            if info == .error {
                Button {
                    onReload?()
                } label: {
                    Text(Strings.Files.Error.reload)
                        .padding()
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SemanticColors.Label.textDefault.color)
                        .frame(maxHeight: 35)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .stroke(SemanticColors.Button.borderSecondaryEnabled.color, lineWidth: 1)

                        )
                }
                .accessibilityLabel(Strings.Files.Error.reload)
                .accessibilityIdentifier("filesBrowser.reloadButton")
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
        .padding()
    }
}

struct LoadMoreView: View {
    let isLoading: Bool
    let onLoadMore: () -> Void

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Button(Strings.Files.LoadMore.title, action: onLoadMore)
                    .accessibilityLabel(Accessibility.Files.LoadMore.title)
                    .accessibilityIdentifier("load-more")
                    .buttonStyle(.borderless)
                    .wireTextStyle(.body3)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)

            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    }

}
