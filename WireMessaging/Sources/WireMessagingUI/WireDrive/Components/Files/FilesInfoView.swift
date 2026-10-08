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

    enum Scope: Hashable {
        case files(conversation: Conversation, isFolder: Bool = false)
        case recycleBin(isFolder: Bool)
        case search
        case moveToFolder
        case editFile

        enum Conversation {
            case all
            case one
        }
    }

    enum Kind: Hashable {
        case preparing
        case empty
        case error(isConnectionError: Bool)
    }

    let scope: Scope
    let kind: Kind
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 25) {
            if let title {
                Text(title)
                    .padding([.leading, .trailing], kind == .preparing ? 30 : 0)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SemanticColors.Label.textDefault.color)
                    .accessibilityIdentifier(titleAccessibilityId)
            }

            if let message {
                Text(message)
                    .padding([.leading, .trailing], kind == .preparing ? 0 : 30)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SemanticColors.Label.baseSecondaryText.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(messageAccessibilityId)
            }

            switch kind {
            case .empty:
                learnMoreLink()
            case .error:
                retryButton
            case .preparing:
                EmptyView()
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
        .padding()
    }

    var title: String? {
        switch kind {
        case .preparing:
            Strings.Files.PendingCells.title
        case .empty:
            switch scope {
            case let .files(conversation, isFolder):
                if isFolder {
                    nil
                } else {
                    switch conversation {
                    case .all: Strings.AllFiles.NoData.title
                    case .one: Strings.Files.NoData.title
                    }
                }
            case let .recycleBin(isFolder):
                if isFolder {
                    Strings.RecycleBin.EmptyFolder.title
                } else {
                    Strings.Files.NoData.title
                }
            case .search:
                Strings.Files.NoSearchResults.title
            case .moveToFolder, .editFile:
                nil
            }
        case let .error(isConnectionError):
            switch scope {
            case .moveToFolder, .editFile:
                if isConnectionError {
                    L10n.Localizable.General.Error.NoInternet.title
                } else {
                    L10n.Localizable.General.Error.Unknown.title
                }
            default:
                if isConnectionError {
                    Strings.Files.Error.NoConnection.title
                } else {
                    Strings.Files.Error.title
                }
            }
        }
    }

    var message: String? {
        switch kind {
        case .preparing:
            Strings.Files.PendingCells.message
        case .empty:
            switch scope {
            case let .files(conversation, isFolder):
                if isFolder {
                    Strings.Files.EmptyFolder.message
                } else {
                    switch conversation {
                    case .all: Strings.AllFiles.NoData.message
                    case .one: Strings.Files.NoData.message
                    }
                }
            case let .recycleBin(isFolder):
                if isFolder {
                    Strings.RecycleBin.EmptyFolder.message
                } else {
                    Strings.Files.NoData.message
                }
            case .search:
                Strings.Files.NoSearchResults.message
            case .moveToFolder:
                Strings.Files.MoveToFolder.noSubfolders
            case .editFile:
                nil
            }
        case let .error(isConnectionError):
            switch scope {
            case .moveToFolder, .editFile:
                if isConnectionError {
                    L10n.Localizable.General.Error.NoInternet.message
                } else {
                    L10n.Localizable.General.Error.Unknown.message
                }
            default:
                if isConnectionError {
                    Strings.Files.Error.NoConnection.message
                } else {
                    Strings.Files.Error.message
                }
            }
        }
    }

    var titleAccessibilityId: String? {
        typealias Identifiers = Locators.WireDrive.FilesInfoPage

        return switch kind {
        case .preparing:
            Identifiers.preparingFilesTitle.rawValue
        case .empty:
            switch scope {
            case .recycleBin, .files, .moveToFolder:
                Identifiers.noFilesTitle.rawValue
            case .search:
                Identifiers.noFilesSearchTitle.rawValue
            case .editFile:
                nil
            }
        case .error:
            Identifiers.errorTitle.rawValue
        }
    }

    var messageAccessibilityId: String? {
        typealias Identifiers = Locators.WireDrive.FilesInfoPage

        return switch kind {
        case .preparing:
            Identifiers.preparingFilesMessage.rawValue
        case .empty:
            switch scope {
            case .recycleBin, .files, .moveToFolder:
                Identifiers.noFilesMessage.rawValue
            case .search:
                Identifiers.noFilesSearchMessage.rawValue
            case .editFile:
                nil
            }
        case .error:
            Identifiers.errorMessage.rawValue
        }
    }

    private var learnMoreLinkData: (title: String, destination: URL)? {
        switch kind {
        case .empty:
            switch scope {
            case let .files(conversation, isFolder):
                if isFolder {
                    nil
                } else {
                    switch conversation {
                    case .all:
                        (Strings.AllFiles.NoData.learnMore, URL.accessAllFilesAccrossConversations)
                    case .one:
                        (Strings.Files.NoData.learnMore, URL.sharedDriveInConversations)
                    }
                }
            case .search, .moveToFolder, .recycleBin, .editFile:
                nil
            }
        case .error, .preparing:
            nil
        }
    }

    @ViewBuilder
    private func learnMoreLink() -> some View {
        if let link = learnMoreLinkData {
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
            let isConnectionError = kind == .error(isConnectionError: true)
            let text = if isConnectionError {
                Strings.Files.Error.NoConnection.retry
            } else {
                Strings.Files.Error.retry
            }

            Text(text)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(SemanticColors.Label.textDefault.color)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            SemanticColors.Button.borderSecondaryEnabled.color,
                            lineWidth: 1
                        )
                }
        }
        .accessibilityIdentifier(Locators.WireDrive.FilesInfoPage.retryButton)
    }
}

private extension View {
    @ViewBuilder
    func accessibilityIdentifier(_ id: String?) -> some View {
        if let id {
            accessibilityIdentifier(id)
        } else {
            self
        }
    }
}

#Preview("empty files, all conversations") {
    FilesInfoView(scope: .files(conversation: .all), kind: .empty)
}

#Preview("empty files, one conversation") {
    FilesInfoView(scope: .files(conversation: .one), kind: .empty)
}

#Preview("empty files, one conversation, folder") {
    FilesInfoView(scope: .files(conversation: .one, isFolder: true), kind: .empty)
}

#Preview("empty recycle bin") {
    FilesInfoView(scope: .recycleBin(isFolder: false), kind: .empty)
}

#Preview("empty recycle bin, folder") {
    FilesInfoView(scope: .recycleBin(isFolder: true), kind: .empty)
}

#Preview("empty move-to-folder") {
    FilesInfoView(scope: .moveToFolder, kind: .empty)
}

#Preview("empty search") {
    FilesInfoView(scope: .search, kind: .empty)
}

#Preview("preparing files") {
    FilesInfoView(scope: .files(conversation: .all), kind: .preparing)
}

#Preview("error files") {
    FilesInfoView(scope: .files(conversation: .all), kind: .error(isConnectionError: false))
}

#Preview("error files, no internet") {
    FilesInfoView(scope: .files(conversation: .all), kind: .error(isConnectionError: true))
}

#Preview("error move-to-folder") {
    FilesInfoView(scope: .moveToFolder, kind: .error(isConnectionError: false))
}

#Preview("error move-to-folder, no internet") {
    FilesInfoView(scope: .moveToFolder, kind: .error(isConnectionError: true))
}

#Preview("error edit-file") {
    FilesInfoView(scope: .moveToFolder, kind: .error(isConnectionError: false))
}

#Preview("error edit-file, no internet") {
    FilesInfoView(scope: .moveToFolder, kind: .error(isConnectionError: true))
}
