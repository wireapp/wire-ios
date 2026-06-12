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

extension View {
    /// Adds file preview handling to the view using `FilePreviewModifier`.
    ///
    /// The preview flow is automatically selected depending on the file
    /// read access and preview source.
    func quickFilePreview(
        _ previewItem: Binding<QuickPreviewItem?>
    ) -> some View {
        modifier(
            FilePreviewModifier(
                previewItem: previewItem
            )
        )
    }
}

/// Custom modifier to handle file preview presentation depending on the file read access and preview source.
///
/// **Preview flows**
/// - Read-only files use custom previewers (`FilePreviewView`) to restrict QuickLook actions to guests users on a Drive
/// conversation.
/// - Editable files use the native SwiftUI `.quickLookPreview` for team users on a Drive conversation.
/// - `QuickLookPreviewPresenter` wraps a custom QLPreviewController subclass used only to fix an iPad QuickLook
/// presentation/dismissal glitch.
struct FilePreviewModifier: ViewModifier {
    @Binding var previewItem: QuickPreviewItem?
    @State private var isCustomPreviewerPresented = false
    @State private var url: URL?
    @State private var previewPresenter: QuickLookPreviewPresenter?

    func body(content: Content) -> some View {
        content
            .onChange(of: previewItem, initial: false) { _, newValue in
                guard let previewItem = newValue else {
                    return resetState()
                }

                if previewItem.isReadOnly, isDrivePermissionsFlagEnabled {
                    // uses custom previewers with limited actions
                    isCustomPreviewerPresented = true
                } else {
                    switch previewItem.openFrom {
                    case .drive:
                        // uses `quickLookPreview` with all available actions
                        url = previewItem.url
                    case .conversation:
                        // uses `QLPreviewController` to fix a glitch on iPad.
                        previewPresenter = QuickLookPreviewPresenter(onDismiss: resetState)
                        previewPresenter?.present(url: previewItem.url)
                    }
                }
            }
            .fullScreenCover(isPresented: $isCustomPreviewerPresented, onDismiss: {
                resetState()
            }, content: {
                if let previewItem {
                    FilePreviewView(
                        url: previewItem.url,
                        fileType: previewItem.fileType,
                        name: previewItem.filename
                    )
                }
            })
            .quickLookPreview($url)
    }

    // TODO: [WPB-25941] Remove drive permissions flag when feature is complete
    var isDrivePermissionsFlagEnabled: Bool {
        UserDefaults.standard.bool(forKey: "enableDrivePermissions")
    }

    private func resetState() {
        isCustomPreviewerPresented = false
        url = nil
        previewItem = nil
        previewPresenter = nil
    }
}
