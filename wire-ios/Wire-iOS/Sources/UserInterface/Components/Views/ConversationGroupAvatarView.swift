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

typealias ConversationGroupAvatarViewConversation = ConversationLike

final class ConversationGroupAvatarView: UIView {
    struct Context {
        // an established conversation or self user has a pending request to other users
        let conversation: ConversationGroupAvatarViewConversation
        // we can't add the QualifiedID to ConversationLike because it's an @objc protocol
        let qualifiedID: QualifiedID?
    }

    func configure(context: Context) {
        self.conversation = context.conversation
        iconViewController.view.isHidden = false
    }

    private var conversation: ConversationGroupAvatarViewConversation? = .none {
        didSet {
            guard let conversation else {
                iconViewController.view.isHidden = true
                return
            }

            accessibilityLabel = "Avatar for \(conversation.displayNameWithFallback)"
        }
    }

    private var qualifiedID: QualifiedID? = .none

    var iconViewController: UIViewController {
        let view = WireConversationGroupIconFactory().create(conversationID: qualifiedID!.uuid.uuidString)
        let hostingVC = UIHostingController(rootView: view)
        hostingVC.view.frame = bounds
        hostingVC.view.clipsToBounds = true
        addSubview(hostingVC.view)
        return hostingVC
    }

    init() {
        super.init(frame: .zero)

        autoresizesSubviews = false
        layer.masksToBounds = true
        attachToNearestViewController()
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

        iconViewController.view.frame = bounds.insetBy(dx: 2, dy: 2)

        layer.cornerRadius = 6
        iconViewController.view.layer.cornerRadius = 4
    }


    // An ugly hack to get the view controller so we can properly tie our icon's UIHostingController to it
    // in order to preserve the SwiftUI lifecycle. This is necessary because the view controller is not available.
    private func attachToNearestViewController() {
        guard let parentVC = self.findViewController() else { return }

        parentVC.addChild(iconViewController)
        iconViewController.didMove(toParent: parentVC)
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
}
