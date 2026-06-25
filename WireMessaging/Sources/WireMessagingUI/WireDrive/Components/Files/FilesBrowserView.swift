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

import Combine
import QuickLook
package import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// Allows browsing files shared across all conversations
package struct FilesBrowserView: View {
    @StateObject package var viewModel: FilesViewModel
    package var isBrowsing: Bool { true }

    package init(
        viewModel: @autoclosure @escaping () -> FilesViewModel,
        onOpenRecycleBin: @escaping () -> Void = {},
        onDismissContainer: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    package var body: some View {
        FilesContentView(
            viewModel: viewModel,
            isBrowsing: isBrowsing,
            backgroundColor: ColorTheme.Backgrounds.surface.color,
            toolbarContent: { toolBarContent },
            sheetContent: { sheetContent($0) }
        )
    }
}

// MARK: - Toolbar

private extension FilesBrowserView {
    @ToolbarContentBuilder private var toolBarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.navigationTitle)
                .font(for: .h3)
                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        }
    }
}

private extension FilesBrowserView {
    @ViewBuilder
    func sheetContent(_ navigationItem: FilesViewModel.SheetNavigation) -> some View {
        switch navigationItem {
        case let .shareLink(item):
            ShareLinkView(viewModel: viewModel.shareLinkViewModel(item: item))
        default:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        FilesBrowserView(viewModel: .preview(isBrowsing: true))
    }
}
