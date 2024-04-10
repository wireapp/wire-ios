import UIKit

public struct ConversationListFactory {

    public init() {}

    public func make() -> UIViewController {
        let splitViewController = UISplitViewController(style: .tripleColumn)

        return splitViewController
    }
}
