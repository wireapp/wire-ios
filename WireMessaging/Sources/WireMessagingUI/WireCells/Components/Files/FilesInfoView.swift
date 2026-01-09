//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
    @Environment(\.openURL) private var openURL

    enum Info: Equatable {
        case preparingFiles
        case noFilesFound(scope: Scope)
        case error

        enum Scope: Equatable {
            case allConversations
            case oneConversation
            case recycleBin
        }

        func textForScope(_ scope: Scope) -> String {
            switch scope {
            case .allConversations: Strings.AllFiles.NoData.message
            case .oneConversation: Strings.Files.NoData.message
            case .recycleBin: Strings.RecycleBin.NoData.message
            }
        }

        func accessibilityTextForScope(_ scope: Scope) -> String {
            switch scope {
            case .allConversations: Accessibility.AllFiles.NoData.message
            case .oneConversation: Accessibility.Files.NoData.message
            case .recycleBin: Accessibility.RecycleBin.NoData.message
            }
        }

        var localizedStrings: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                (Strings.Files.PendingCells.title, Strings.Files.PendingCells.message)
            case let .noFilesFound(scope):
                (
                    scope == .oneConversation ? Strings.Files.NoData.title : Strings.AllFiles.NoData.title,
                    textForScope(scope)
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
                    accessibilityTextForScope(scope)
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

        var learnMoreURL: String {
            "https://support.wire.com/hc/en-us/articles/32207745256221-Shared-Drive-in-conversations"
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

            switch info {
            case .noFilesFound:
                learnMoreLink
            case .error:
                reloadButton
            default:
                EmptyView()
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
        .padding()
    }

    private var learnMoreLink: some View {
        Link(
            info == .noFilesFound(scope: .oneConversation) ? Strings.Files.NoData.learnMore : Strings.AllFiles.NoData
                .learnMore,
            destination: URL(string: info.learnMoreURL)!
        )
        .foregroundColor(SemanticColors.Label.baseSecondaryText.color)
        .underline()
    }

    private var reloadButton: some View {
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

#Preview("no files found - single conversation") {
    FilesInfoView(info: .noFilesFound(scope: .oneConversation))
}

#Preview("no files found - all conversations") {
    FilesInfoView(info: .noFilesFound(scope: .allConversations))
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
                    .font(for: .body3)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)

            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    }

}
