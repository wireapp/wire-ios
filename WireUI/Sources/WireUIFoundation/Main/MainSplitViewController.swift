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

public final class MainSplitViewController<Sidebar: MainSidebarProtocol, ConversationList: MainConversationListProtocol>: UISplitViewController, MainSplitViewControllerProtocol {

    public typealias Conversation = UIViewController
    public typealias TabContainer = UIViewController
    public typealias NoConversationPlaceholderBuilder = () -> UIViewController

    // MARK: - Public Properties

    public var sidebar: Sidebar {
        viewController(for: .primary) as! Sidebar
    }

    public var conversationList: ConversationList? {
        get {
            let navigationController = viewController(for: .supplementary) as! UINavigationController
            return navigationController.viewControllers.first.map { $0 as! ConversationList }
        }
        set {
            let navigationController = viewController(for: .supplementary) as! UINavigationController
            navigationController.viewControllers = [newValue].compactMap { $0 }
        }
    }

    public var conversation: Conversation? {
        get {
            let navigationController = viewController(for: .secondary) as! UINavigationController
            if navigationController.viewControllers.first === noConversationPlaceholder {
                return nil
            } else {
                return navigationController.viewControllers.first.map { $0 as! Conversation }
            }
        }
        set {
            let navigationController = viewController(for: .secondary) as! UINavigationController
            navigationController.viewControllers = [newValue ?? noConversationPlaceholder]
        }
    }

    public var tabContainer: TabContainer {
        viewController(for: .compact) as! TabContainer
    }

    // MARK: - Private Properties

    private let noConversationPlaceholder: UIViewController

    // MARK: - Initialization

    public init(
        sidebar: @autoclosure () -> Sidebar,
        noConversationPlaceholder: @autoclosure () -> UIViewController,
        tabContainer: @autoclosure () -> TabContainer
    ) {
        let noConversationPlaceholder = noConversationPlaceholder()
        self.noConversationPlaceholder = noConversationPlaceholder
        super.init(style: .tripleColumn)

        preferredSplitBehavior = .tile
        preferredDisplayMode = .oneBesideSecondary
        preferredPrimaryColumnWidth = 260
        preferredSupplementaryColumnWidth = 320

        setViewController(sidebar(), for: .primary)
        setViewController(UINavigationController(), for: .supplementary)
        setViewController(UINavigationController(rootViewController: noConversationPlaceholder), for: .secondary)
        setViewController(tabContainer(), for: .compact)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // default to showing sidebar in landscape
        if size.width > size.height {
            preferredDisplayMode = .twoBesideSecondary
        } else {
            preferredDisplayMode = .oneBesideSecondary
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let splitViewController = MainSplitViewController<PreviewSidebarViewController, PreviewSidebarViewController>(
            sidebar: PreviewSidebarViewController("sidebar"),
            noConversationPlaceholder: UIHostingController(rootView: Text(verbatim: "no conversation placeholder")),
            tabContainer: UIHostingController(rootView: Text(verbatim: "tab bar controller"))
        )
        splitViewController.conversationList = PreviewSidebarViewController("conversation list")
        return splitViewController
    }()
}

final class PreviewSidebarViewController: UIHostingController<PreviewSidebarView>, MainSidebarProtocol, MainConversationListProtocol {

    // MARK: - MainSidebarProtocol

    var conversationFilter: ConversationFilter?

    enum ConversationFilter: MainConversationListFilterProtocol {
        case favorites, groups, oneOnOne, archived
    }

    // MARK: - MainConversationListProtocol

    var splitViewInterface: MainSplitViewInterface = .expanded

    // MARK: - Life Cycle

    convenience init(_ content: String) {
        self.init(content, .init(uiColor: .systemBackground))
    }

    convenience init(_ content: String, _ backgroundColor: Color) {
        self.init(rootView: PreviewSidebarView(content: content, backgroundColor: backgroundColor))
    }
}

struct PreviewSidebarView: View {
    var content: String
    var backgroundColor: Color
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(content)
                    .ignoresSafeArea()
                Spacer()
            }
            Spacer()
        }.background(backgroundColor)
    }
}
