

import Foundation
import NeedleFoundation
import UserNotifications
import WireAPI
import WireCrypto
import WireDataModel
import WireFoundation

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

private func parent2(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent
}

private func parent3(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent
}

private func parent4(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent
}

private func parent5(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class ShowNotificationDependencya0b9d9633053c7a7a814Provider: ShowNotificationDependency {
    var contentHandler: (UNNotificationContent) -> Void {
        return notificationServiceExtensionFlow.contentHandler
    }
    var accountManager: AccountManager {
        return verifyUserStep.accountManager
    }
    var selectedAccount: Account! {
        return verifyUserStep.selectedAccount
    }
    var sharedUserDefaults: UserDefaults {
        return verifyUserStep.sharedUserDefaults
    }
    var userID: UUID! {
        return processNotificationRequestStep.userID
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return pullEventsStep.conversationLocalStore
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    private let processNotificationRequestStep: ProcessNotificationRequestStep
    private let pullEventsStep: PullEventsStep
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, processNotificationRequestStep: ProcessNotificationRequestStep, pullEventsStep: PullEventsStep, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.processNotificationRequestStep = processNotificationRequestStep
        self.pullEventsStep = pullEventsStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep->ShowNotificationStep
private func factory7cf4b2b30a4398b50d11a8d6d2ede7a2d847c073(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ShowNotificationDependencya0b9d9633053c7a7a814Provider(notificationServiceExtensionFlow: parent5(component) as! NotificationServiceExtensionFlow, processNotificationRequestStep: parent4(component) as! ProcessNotificationRequestStep, pullEventsStep: parent2(component) as! PullEventsStep, verifyUserStep: parent3(component) as! VerifyUserStep)
}
private class VerifyUserDependency86e4082a5d4cc2c665ceProvider: VerifyUserDependency {
    var userID: UUID! {
        return processNotificationRequestStep.userID
    }
    var applicationIdentifier: String {
        return notificationServiceExtensionFlow.applicationIdentifier
    }
    var applicationContainer: URL {
        return notificationServiceExtensionFlow.applicationContainer
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    private let processNotificationRequestStep: ProcessNotificationRequestStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, processNotificationRequestStep: ProcessNotificationRequestStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.processNotificationRequestStep = processNotificationRequestStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep
private func factory1e6574088fa77c7ec1b32a0cb5537ef6f42937db(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerifyUserDependency86e4082a5d4cc2c665ceProvider(notificationServiceExtensionFlow: parent2(component) as! NotificationServiceExtensionFlow, processNotificationRequestStep: parent1(component) as! ProcessNotificationRequestStep)
}
private class GenerateNotificationDependencye9ac54a4aea693448fe3Provider: GenerateNotificationDependency {
    var contentHandler: (UNNotificationContent) -> Void {
        return notificationServiceExtensionFlow.contentHandler
    }
    var accountManager: AccountManager {
        return verifyUserStep.accountManager
    }
    var sharedUserDefaults: UserDefaults {
        return verifyUserStep.sharedUserDefaults
    }
    var userID: UUID! {
        return processNotificationRequestStep.userID
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return pullEventsStep.messageLocalStore
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return pullEventsStep.conversationLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return pullEventsStep.userLocalStore
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    private let processNotificationRequestStep: ProcessNotificationRequestStep
    private let pullEventsStep: PullEventsStep
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, processNotificationRequestStep: ProcessNotificationRequestStep, pullEventsStep: PullEventsStep, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.processNotificationRequestStep = processNotificationRequestStep
        self.pullEventsStep = pullEventsStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep
private func factoryce7e84dac24eba2dbd0b2dfb96ae201a9ec3fe22(_ component: NeedleFoundation.Scope) -> AnyObject {
    return GenerateNotificationDependencye9ac54a4aea693448fe3Provider(notificationServiceExtensionFlow: parent4(component) as! NotificationServiceExtensionFlow, processNotificationRequestStep: parent3(component) as! ProcessNotificationRequestStep, pullEventsStep: parent1(component) as! PullEventsStep, verifyUserStep: parent2(component) as! VerifyUserStep)
}
private class PullEventsDependency53707bfe7fe589fd7ad1Provider: PullEventsDependency {
    var userID: UUID! {
        return processNotificationRequestStep.userID
    }
    var coreData: CoreDataStack {
        return verifyUserStep.coreData
    }
    var cookieStorage: any CookieStorageProtocol {
        return verifyUserStep.cookieStorage
    }
    var applicationContainer: URL {
        return notificationServiceExtensionFlow.applicationContainer
    }
    var applicationIdentifier: String {
        return notificationServiceExtensionFlow.applicationIdentifier
    }
    var sharedUserDefaults: UserDefaults {
        return verifyUserStep.sharedUserDefaults
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    private let processNotificationRequestStep: ProcessNotificationRequestStep
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, processNotificationRequestStep: ProcessNotificationRequestStep, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.processNotificationRequestStep = processNotificationRequestStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep
private func factoryf4ab58fd6d9a40f32066d10a95ce62f6a7bfe6db(_ component: NeedleFoundation.Scope) -> AnyObject {
    return PullEventsDependency53707bfe7fe589fd7ad1Provider(notificationServiceExtensionFlow: parent3(component) as! NotificationServiceExtensionFlow, processNotificationRequestStep: parent2(component) as! ProcessNotificationRequestStep, verifyUserStep: parent1(component) as! VerifyUserStep)
}

#else
extension ShowNotificationStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\ShowNotificationDependency.contentHandler] = "contentHandler-(UNNotificationContent) -> Void"
        keyPathToName[\ShowNotificationDependency.accountManager] = "accountManager-AccountManager"
        keyPathToName[\ShowNotificationDependency.selectedAccount] = "selectedAccount-Account!"
        keyPathToName[\ShowNotificationDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        keyPathToName[\ShowNotificationDependency.userID] = "userID-UUID!"
        keyPathToName[\ShowNotificationDependency.conversationLocalStore] = "conversationLocalStore-any ConversationLocalStoreProtocol"
    }
}
extension ProcessNotificationRequestStep: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["userID-UUID!"] = { [unowned self] in self.userID as Any }
    }
}
extension VerifyUserStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerifyUserDependency.userID] = "userID-UUID!"
        keyPathToName[\VerifyUserDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\VerifyUserDependency.applicationContainer] = "applicationContainer-URL"
        localTable["selectedAccount-Account!"] = { [unowned self] in self.selectedAccount as Any }
        localTable["accountManager-AccountManager"] = { [unowned self] in self.accountManager as Any }
        localTable["sharedUserDefaults-UserDefaults"] = { [unowned self] in self.sharedUserDefaults as Any }
        localTable["cookieStorage-any CookieStorageProtocol"] = { [unowned self] in self.cookieStorage as Any }
        localTable["coreData-CoreDataStack"] = { [unowned self] in self.coreData as Any }
    }
}
extension NotificationServiceExtensionFlow: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["contentHandler-(UNNotificationContent) -> Void"] = { [unowned self] in self.contentHandler as Any }
        localTable["applicationIdentifier-String"] = { [unowned self] in self.applicationIdentifier as Any }
        localTable["applicationContainer-URL"] = { [unowned self] in self.applicationContainer as Any }
    }
}
extension GenerateNotificationStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\GenerateNotificationDependency.contentHandler] = "contentHandler-(UNNotificationContent) -> Void"
        keyPathToName[\GenerateNotificationDependency.accountManager] = "accountManager-AccountManager"
        keyPathToName[\GenerateNotificationDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        keyPathToName[\GenerateNotificationDependency.userID] = "userID-UUID!"
        keyPathToName[\GenerateNotificationDependency.messageLocalStore] = "messageLocalStore-any MessageLocalStoreProtocol"
        keyPathToName[\GenerateNotificationDependency.conversationLocalStore] = "conversationLocalStore-any ConversationLocalStoreProtocol"
        keyPathToName[\GenerateNotificationDependency.userLocalStore] = "userLocalStore-any UserLocalStoreProtocol"

    }
}
extension PullEventsStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\PullEventsDependency.userID] = "userID-UUID!"
        keyPathToName[\PullEventsDependency.coreData] = "coreData-CoreDataStack"
        keyPathToName[\PullEventsDependency.cookieStorage] = "cookieStorage-any CookieStorageProtocol"
        keyPathToName[\PullEventsDependency.applicationContainer] = "applicationContainer-URL"
        keyPathToName[\PullEventsDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\PullEventsDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        localTable["conversationLocalStore-any ConversationLocalStoreProtocol"] = { [unowned self] in self.conversationLocalStore as Any }
        localTable["messageLocalStore-any MessageLocalStoreProtocol"] = { [unowned self] in self.messageLocalStore as Any }
        localTable["userLocalStore-any UserLocalStoreProtocol"] = { [unowned self] in self.userLocalStore as Any }
    }
}


#endif

private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

#if !NEEDLE_DYNAMIC

@inline(never) private func register1() {
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep->ShowNotificationStep", factory7cf4b2b30a4398b50d11a8d6d2ede7a2d847c073)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep", factoryEmptyDependencyProvider)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep", factory1e6574088fa77c7ec1b32a0cb5537ef6f42937db)
    registerProviderFactory("^->NotificationServiceExtensionFlow", factoryEmptyDependencyProvider)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep", factoryce7e84dac24eba2dbd0b2dfb96ae201a9ec3fe22)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep", factoryf4ab58fd6d9a40f32066d10a95ce62f6a7bfe6db)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
