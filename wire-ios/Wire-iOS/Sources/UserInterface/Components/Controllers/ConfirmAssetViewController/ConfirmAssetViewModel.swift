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

import UIKit

struct ConfirmAssetViewModel {

    enum ToolbarPlacement: Equatable {
        case none
        case insideImage
        case bottomPanel
    }

    struct DisplayState: Equatable {
        let toolbarPlacement: ToolbarPlacement
        let cancelButtonTitle: String
        let confirmButtonTitle: String
        let imageAspectRatio: CGFloat?

        var showsEditingOptions: Bool {
            toolbarPlacement != .none
        }

        var showsToolbarInsideImage: Bool {
            toolbarPlacement == .insideImage
        }

        var showsToolbarInBottomPanel: Bool {
            toolbarPlacement == .bottomPanel
        }
    }

    let displayState: DisplayState

    init(asset: ConfirmAssetViewController.Asset) {
        let toolbarPlacement: ToolbarPlacement
        let imageAspectRatio: CGFloat?

        switch asset {
        case let .image(mediaAsset):
            imageAspectRatio = mediaAsset.size.height / mediaAsset.size.width

            if mediaAsset is UIImage {
                toolbarPlacement = mediaAsset.size.width > 192 && mediaAsset.size.height > 96
                    ? .insideImage
                    : .bottomPanel
            } else {
                toolbarPlacement = .none
            }

        case .video:
            toolbarPlacement = .none
            imageAspectRatio = nil
        }

        self.displayState = DisplayState(
            toolbarPlacement: toolbarPlacement,
            cancelButtonTitle: L10n.Localizable.ImageConfirmer.cancel,
            confirmButtonTitle: L10n.Localizable.ImageConfirmer.confirm,
            imageAspectRatio: imageAspectRatio
        )
    }
}
