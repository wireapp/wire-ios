import UIKit

public struct ConversationListFactory {

    public init() {}

    public func make() -> UIViewController {
        let splitViewController = UISplitViewController(style: .tripleColumn)
        splitViewController.viewControllers = [
            SidebarViewController(),
            .init(),
            .init()
        ]
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        return splitViewController
    }
}
