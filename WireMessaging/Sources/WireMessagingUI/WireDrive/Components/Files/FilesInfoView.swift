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
        case noFilesFound(scope: Scope, isSearch: Bool)
        case error(isConnectionError: Bool)

        enum Scope: Equatable {
            case allConversations
            case oneConversation
            case recycleBin

            var learnMoreURL: URL {
                switch self {
                case .oneConversation:
                    URL.sharedDriveInConversations
                case .allConversations:
                    URL.accessAllFilesAccrossConversations
                case .recycleBin:
                    URL.accessRecycleBin
                }
            }
        }

        func textFor(scope: Scope, isSearch: Bool) -> String {
            if isSearch {
                Strings.Files.NoSearchResults.message
            } else {
                switch scope {
                case .allConversations: Strings.AllFiles.NoData.message
                case .oneConversation: Strings.Files.NoData.message
                case .recycleBin: Strings.RecycleBin.NoData.message
                }
            }
        }

        func accessibilityTextFor(scope: Scope, isSearch: Bool) -> String {
            if isSearch {
                Accessibility.Files.NoSearchResults.message
            } else {
                switch scope {
                case .allConversations: Accessibility.AllFiles.NoData.message
                case .oneConversation: Accessibility.Files.NoData.message
                case .recycleBin: Accessibility.RecycleBin.NoData.message
                }
            }
        }

        var localizedStrings: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                (Strings.Files.PendingCells.title, Strings.Files.PendingCells.message)
            case let .noFilesFound(scope, isSearch):
                (
                    isSearch ? Strings.Files.NoSearchResults.title :
                        scope == .oneConversation || scope == .recycleBin ?
                        Strings.Files.NoData.title : Strings.AllFiles.NoData.title,
                    textFor(scope: scope, isSearch: isSearch)
                )
            case let .error(isConnectionError):
                if isConnectionError {
                    (Strings.Files.Error.NoConnection.title, Strings.Files.Error.NoConnection.message)
                } else {
                    (Strings.Files.Error.title, Strings.Files.Error.message)
                }
            }
        }

        var accessibilityStrings: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                (Accessibility.Files.PendingCells.title, Accessibility.Files.PendingCells.message)
            case let .noFilesFound(scope, isSearch):
                (
                    Accessibility.Files.NoData.title,
                    accessibilityTextFor(scope: scope, isSearch: isSearch)
                )
            case let .error(isConnectionError):
                if isConnectionError {
                    (Accessibility.Files.Error.NoConnection.title, Strings.Files.Error.NoConnection.message)
                } else {
                    (Accessibility.Files.Error.title, Strings.Files.Error.message)
                }
            }
        }

        var accessibilityIdentifiers: (title: String, message: String) {
            switch self {
            case .preparingFiles:
                ("preparing-files-title", "preparing-files-message")
            case let .noFilesFound(scope, isSearch):
                if isSearch {
                    (
                        "no-files-search-title",
                        "no-files-search-message"
                    )
                } else {
                    (
                        "no-files-title",
                        scope == .allConversations ? "no-files-all-conversations-message" : "no-files-message"
                    )
                }
            case .error:
                ("error-title", "error-message")
            }
        }
    }

    let info: Info
    var onRetry: (() -> Void)?

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
            case let .noFilesFound(scope, isSearch):
                if !isSearch {
                    learnMoreLink(scope: scope)
                }
            case .error:
                retryButton
            default:
                EmptyView()
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
        .padding()
    }

    private func learnMoreLink(scope: Info.Scope) -> some View {
        let linkTitle = switch scope {
        case .oneConversation:
            Strings.Files.NoData.learnMore
        case .allConversations:
            Strings.AllFiles.NoData.learnMore
        case .recycleBin:
            Strings.RecycleBin.NoData.learnMore
        }

        return Link(destination: scope.learnMoreURL) {
            Text(linkTitle)
                .foregroundColor(SemanticColors.Label.baseSecondaryText.color)
                .underline()
        }
    }

    private var retryButton: some View {
        Button {
            onRetry?()
        } label: {
            Text(info == .error(isConnectionError: true) ? Strings.Files.Error.NoConnection.retry : Strings.Files.Error
                .retry)
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
        .accessibilityLabel(Strings.Files.Error.retry)
        .accessibilityIdentifier("filesBrowser.retryButton")
    }

}

#Preview("no files found - single conversation") {
    FilesInfoView(info: .noFilesFound(scope: .oneConversation, isSearch: false))
}

#Preview("no files found - all conversations") {
    FilesInfoView(info: .noFilesFound(scope: .allConversations, isSearch: false))
}

#Preview("no files found - recycle bin") {
    FilesInfoView(info: .noFilesFound(scope: .recycleBin, isSearch: false))
}

#Preview("no files found via search - all conversations") {
    FilesInfoView(info: .noFilesFound(scope: .allConversations, isSearch: true))
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
