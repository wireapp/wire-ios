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
import WireLocators

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FilesInfoView: View {
    @Environment(\.openURL) private var openURL

    enum Info: Equatable {
        case preparingFiles
        case noFilesFound(scope: Scope, isSearch: Bool, isFolder: Bool = false)
        case error(isConnectionError: Bool)

        enum Scope: Equatable {
            case allConversations
            case oneConversation
            case recycleBin
        }

        var learnMoreLinkData: (title: String, destination: URL)? {
            switch self {
            case let .noFilesFound(scope, isSearch, isFolder):
                if !isSearch, !isFolder {
                    switch scope {
                    case .oneConversation:
                        (Strings.Files.NoData.learnMore, URL.sharedDriveInConversations)
                    case .allConversations:
                        (Strings.AllFiles.NoData.learnMore, URL.accessAllFilesAccrossConversations)
                    case .recycleBin:
                        (Strings.RecycleBin.NoData.learnMore, URL.accessRecycleBin)
                    }
                } else {
                    nil
                }
            default:
                nil
            }
        }

        var title: String? {
            switch self {
            case .preparingFiles:
                Strings.Files.PendingCells.title
            case let .error(isConnectionError):
                if isConnectionError {
                    Strings.Files.Error.NoConnection.title
                } else {
                    Strings.Files.Error.title
                }
            case let .noFilesFound(scope, isSearch, isFolder):
                if isSearch {
                    Strings.Files.NoSearchResults.title
                } else {
                    if !isFolder {
                        switch scope {
                        case .allConversations:
                            Strings.AllFiles.NoData.title
                        case .oneConversation:
                            Strings.Files.NoData.title
                        case .recycleBin:
                            Strings.Files.NoData.title
                        }
                    } else {
                        nil
                    }
                }
            }
        }

        var message: String {
            switch self {
            case .preparingFiles:
                Strings.Files.PendingCells.message
            case let .error(isConnectionError):
                if isConnectionError {
                    Strings.Files.Error.NoConnection.message
                } else {
                    Strings.Files.Error.message
                }
            case let .noFilesFound(scope, isSearch, isFolder):
                if isSearch {
                    Strings.Files.NoSearchResults.message
                } else {
                    if !isFolder {
                        switch scope {
                        case .allConversations:
                            Strings.AllFiles.NoData.message
                        case .oneConversation:
                            Strings.Files.NoData.message
                        case .recycleBin:
                            Strings.Files.NoData.message
                        }
                    } else {
                        switch scope {
                        case .allConversations, .oneConversation:
                            Strings.Files.EmptyFolder.message
                        case .recycleBin:
                            Strings.RecycleBin.EmptyFolder.message
                        }
                    }
                }
            }
        }

        var titleAccessibilityId: String {
            typealias Identifiers = Locators.WireDrive.FilesInfoPage

            return switch self {
            case .preparingFiles:
                Identifiers.preparingFilesTitle.rawValue
            case .error:
                Identifiers.errorTitle.rawValue
            case let .noFilesFound(_, isSearch, _):
                if isSearch {
                    Identifiers.noFilesSearchTitle.rawValue
                } else {
                    Identifiers.noFilesTitle.rawValue
                }
            }
        }

        var messageAccessibilityId: String {
            typealias Identifiers = Locators.WireDrive.FilesInfoPage

            return switch self {
            case .preparingFiles:
                Identifiers.preparingFilesMessage.rawValue
            case .error:
                Identifiers.errorMessage.rawValue
            case let .noFilesFound(_, isSearch, _):
                if isSearch {
                    Identifiers.noFilesSearchMessage.rawValue
                } else {
                    Identifiers.noFilesMessage.rawValue
                }
            }
        }
    }

    let info: Info
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 25) {
            if let title = info.title {
                Text(title)
                    .padding([.leading, .trailing], info == .preparingFiles ? 30 : 0)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SemanticColors.Label.textDefault.color)
                    .accessibilityIdentifier(info.titleAccessibilityId)
            }

            Text(info.message)
                .padding([.leading, .trailing], info == .preparingFiles ? 0 : 30)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(SemanticColors.Label.baseSecondaryText.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(info.messageAccessibilityId)

            switch info {
            case .noFilesFound:
                learnMoreLink()
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

    @ViewBuilder
    private func learnMoreLink() -> some View {
        if let link = info.learnMoreLinkData {
            Link(destination: link.destination) {
                Text(link.title)
                    .foregroundColor(SemanticColors.Label.baseSecondaryText.color)
                    .underline()
            }
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
        .accessibilityIdentifier(Locators.WireDrive.FilesInfoPage.retryButton)
    }
}

#Preview("no files found - single conversation") {
    FilesInfoView(info: .noFilesFound(scope: .oneConversation, isSearch: false))
}

#Preview("no files found - all conversations") {
    FilesInfoView(info: .noFilesFound(scope: .allConversations, isSearch: false))
}

#Preview("no files found - all conversations - folder") {
    FilesInfoView(info: .noFilesFound(scope: .allConversations, isSearch: false, isFolder: true))
}

#Preview("no files found - recycle bin") {
    FilesInfoView(info: .noFilesFound(scope: .recycleBin, isSearch: false))
}

#Preview("no files found - recycle bin - folder") {
    FilesInfoView(info: .noFilesFound(scope: .recycleBin, isSearch: false, isFolder: true))
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
                    .accessibilityIdentifier(Locators.WireDrive.FilesInfoPage.loadMore.rawValue)
                    .buttonStyle(.borderless)
                    .font(for: .body3)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)

            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    }

}
