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
import UniformTypeIdentifiers
import WireMessagingDomain

struct ZipBrowserView: View {
    let node: ZipNode
    let archiveURL: URL

    @Binding var quickPreviewItem: QuickPreviewItem?

    var body: some View {
        List {
            ForEach(node.children) { child in
                if child.isDirectory {
                    navigationButton(child: child)
                } else {
                    previewButton(child: child)
                }
            }
        }
    }

    @ViewBuilder
    private func navigationButton(child: ZipNode) -> some View {
        NavigationLink {
            ZipBrowserView(
                node: child,
                archiveURL: archiveURL,
                quickPreviewItem: $quickPreviewItem
            )
        } label: {
            Label(
                child.name,
                image: WireDriveFileType.folder.imageResource
            ).foregroundStyle(.default)
        }
    }

    @ViewBuilder
    private func previewButton(child: ZipNode) -> some View {
        Button {
            Task {
                guard let url = ZipExtractor.extractEntry(
                    child.path,
                    from: archiveURL
                ) else { return }

                quickPreviewItem = QuickPreviewItem(
                    url: url,
                    fileType: fileType(for: child),
                    filename: child.name,
                    isReadOnly: true,
                    openFrom: .drive // we don't really mind where it's open from.
                )
            }
        } label: {
            Label(
                child.name,
                image: fileType(for: child).imageResource
            ).foregroundStyle(.default)
        }
    }

    private func fileType(for node: ZipNode) -> WireDriveFileType {
        let fileExtension = URL(fileURLWithPath: node.name).pathExtension
        let fileType = UTType(filenameExtension: fileExtension)
        return WireDriveFileType.make(type: fileType, fileExtension: fileExtension)
    }
}
