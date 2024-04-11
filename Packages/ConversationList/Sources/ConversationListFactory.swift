import UIKit

public struct ConversationListFactory {

    public init() {}

    public func make() -> UIViewController {
        UIStoryboard(name: "Main", bundle: .module).instantiateInitialViewController()!
    }
}
