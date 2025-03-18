//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireConversationsUIBindings
import WireSyncEngine

typealias ConversationGroupAvatarViewConversation = ConversationLike & HasQualifiedID

final class ConversationGroupAvatarView: UIView {
    struct Context {
        // an established conversation or self user has a pending request to other users
        let conversation: ConversationGroupAvatarViewConversation
    }

    func configure(context: Context) {
        let conversation = context.conversation
        self.conversation = conversation

        let iconView = Self.iconView(for: context.conversation.qualifiedID)

        let hostingVC = UIHostingController(rootView: iconView)
        hostingVC.view.frame = iconContainer.frame
        hostingVC.view.clipsToBounds = true

        iconViewController?.removeFromParent()
        iconViewController?.view.removeFromSuperview()

        iconContainer.addSubview(hostingVC.view)
        iconViewController = hostingVC
        attachToNearestViewController(childVC: hostingVC)

        accessibilityLabel = "Avatar for \(conversation.displayNameWithFallback)"
    }

    private var conversation: ConversationGroupAvatarViewConversation? = .none

    private var qualifiedID: QualifiedID? = .none

    lazy var iconContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.frame = bounds
        view.clipsToBounds = true
        view.layer.cornerRadius = 4
        return view
    }()

    private var iconViewController: UIViewController?

    init() {
        super.init(frame: .zero)

        autoresizesSubviews = false
        layer.masksToBounds = true
        addSubview(iconContainer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else {
            return
        }

        iconContainer.frame = bounds
        iconViewController?.view.frame = iconContainer.frame

        layer.cornerRadius = 6
        iconContainer.layer.cornerRadius = 4
    }

    // An ugly hack to get the view controller so we can properly tie our icon's UIHostingController to it
    // in order to preserve the SwiftUI lifecycle. This is necessary because the view controller is not available.
    private func attachToNearestViewController(childVC: UIViewController) {
        guard let parentVC = findViewController() else { return }

        parentVC.addChild(childVC)
        childVC.didMove(toParent: parentVC)
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }

    @ViewBuilder
    private static func iconView(for qualifiedID: QualifiedID?) -> some View {
        if let qualifiedID {
            WireConversationGroupIconFactory().create(conversationID: qualifiedID.uuid.uuidString)
        } else {
            EmptyView()
        }
    }
}
