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

import QuickLook

/// A workaround for presenting the QuickLookPreview on iPad:
/// With the previous implementation, the SwiftUI `.quickLookPreview()` modifier, the preview immediately closed itself
/// on iPad, because it was presented from within a split presentation.
/// This approach instead finds the currently presented view controller and presents the `QLPreviewController` manually
/// on top of it via UIKit.
enum QuickLookPreviewPresenter {
    private class DataSource: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
            url as (any QLPreviewItem)
        }
    }

    @MainActor
    static func present(url: URL) {
        guard let topVC = topmostPresentedViewController() else { return }

        let dataSource = DataSource(url: url)

        let qlController = QLPreviewController()
        qlController.dataSource = dataSource

        topVC.present(qlController, animated: true)
    }

    @MainActor
    private static func topmostPresentedViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let rootVC = scene.windows.first?.rootViewController else { return nil }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        return topVC
    }
}
