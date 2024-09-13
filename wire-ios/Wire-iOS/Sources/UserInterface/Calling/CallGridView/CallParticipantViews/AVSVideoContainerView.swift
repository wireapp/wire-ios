//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import struct WireSystem.WireLogger

/// A placeholder container for AVSVideo to start the rendering only if the view is instantiated and setup.
final class AVSVideoContainerView: UIView {
    private weak var videoView: UIView?

    func setupVideoView(_ view: UIView) {
        guard videoView == nil else {
            WireLogger.ui.error(
                "video view cannot be added, because it contains already a view!",
                attributes: .safePublic
            )
            assertionFailure("video view cannot be added, because it contains already a view!")
            return
        }

        videoView = view
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
