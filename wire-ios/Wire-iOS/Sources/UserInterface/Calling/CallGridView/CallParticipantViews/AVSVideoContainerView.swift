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

final class AVSVideoContainerView: UIView {

    var shouldFill: Bool {
        get {
            videoView?.shouldFill == true
        }
        set {
            videoView?.shouldFill = newValue
        }
    }

    private weak var videoView: (any AVSVideoViewProtocol)?

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    func addVideoView(_ view: any AVSVideoViewProtocol) {
        guard videoView == nil else {
            WireLogger.ui.error(
                "video view cannot be added, because it contains already a view!",
                attributes: .safePublic
            )
            assertionFailure("video view cannot be added, because it contains already a view!")
            return
        }

        self.videoView = view
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func removeVideoView() {
        videoView?.removeFromSuperview()
    }
}
