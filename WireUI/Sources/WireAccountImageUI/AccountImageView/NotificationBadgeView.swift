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

import SwiftUI
import WireDesign

// MARK: -


final class NotificationBadgeView: UIImageView {

    init() {
        super.init(image: .notificationBadgeInfo)
    }

    var showNotificationsBadge: Bool {
        get { !isHidden }
        set { isHidden = !newValue }
    }

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        image = .notificationBadgeInfo
        contentMode = .scaleAspectFit
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    VStack {
        NotificationsBadgeViewRepresentable(showNotifications: false)
        NotificationsBadgeViewRepresentable(showNotifications: true)
    }
    .background(Color(UIColor.systemGray2))
}

private struct NotificationsBadgeViewRepresentable: UIViewRepresentable {
    @State private(set) var showNotifications: Bool
    func makeUIView(context: Context) -> NotificationBadgeView { .init() }
    func updateUIView(_ view: NotificationBadgeView, context: Context) {
        view.isHidden = !showNotifications
    }
}
