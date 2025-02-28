

import CoreData
import Foundation
import NeedleFoundation
import UserNotifications
import WireAPI
import WireCrypto
import WireDataModel
import WireFoundation
import WireLogging

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

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class PullEventsDependency2fd4ab45fd1c7ccdf95cProvider: PullEventsDependency {
    var userID: UUID {
        return rootComponent.userID
    }
    var coreData: CoreDataStack {
        return verifyUserComponent.coreData
    }
    var cookieStorage: any CookieStorageProtocol {
        return verifyUserComponent.cookieStorage
    }
    var selectedAccount: Account {
        return rootComponent.selectedAccount
    }
    var applicationContainer: URL {
        return rootComponent.applicationContainer
    }
    var applicationIdentifier: String {
        return rootComponent.applicationIdentifier
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return verifyUserComponent.messageLocalStore
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return verifyUserComponent.conversationLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return verifyUserComponent.userLocalStore
    }
    private let rootComponent: RootComponent
    private let verifyUserComponent: VerifyUserComponent
    init(rootComponent: RootComponent, verifyUserComponent: VerifyUserComponent) {
        self.rootComponent = rootComponent
        self.verifyUserComponent = verifyUserComponent
    }
}
/// ^->RootComponent->VerifyUserComponent->PullEventsComponent
private func factoryb76115b3e674a8bbffc00e4ca4825856fdf1a57c(_ component: NeedleFoundation.Scope) -> AnyObject {
    return PullEventsDependency2fd4ab45fd1c7ccdf95cProvider(rootComponent: parent2(component) as! RootComponent, verifyUserComponent: parent1(component) as! VerifyUserComponent)
}
private class GenerateNotificationDependency56a07c37e817db4ed050Provider: GenerateNotificationDependency {
    var contentHandler: (UNNotificationContent) -> Void {
        return rootComponent.contentHandler
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return verifyUserComponent.messageLocalStore
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return verifyUserComponent.conversationLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return verifyUserComponent.userLocalStore
    }
    private let rootComponent: RootComponent
    private let verifyUserComponent: VerifyUserComponent
    init(rootComponent: RootComponent, verifyUserComponent: VerifyUserComponent) {
        self.rootComponent = rootComponent
        self.verifyUserComponent = verifyUserComponent
    }
}
/// ^->RootComponent->VerifyUserComponent->PullEventsComponent->GenerateNotificationComponent
private func factoryfc879bce2c4eef2d1ee9b0226f348eb7db75c336(_ component: NeedleFoundation.Scope) -> AnyObject {
    return GenerateNotificationDependency56a07c37e817db4ed050Provider(rootComponent: parent3(component) as! RootComponent, verifyUserComponent: parent2(component) as! VerifyUserComponent)
}
private class VerifyUserDependency1ae953de4ac1a2a84a5dProvider: VerifyUserDependency {
    var userID: UUID {
        return rootComponent.userID
    }
    var selectedAccount: Account {
        return rootComponent.selectedAccount
    }
    var applicationIdentifier: String {
        return rootComponent.applicationIdentifier
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->VerifyUserComponent
private func factoryd5eeee80e5892aa86d18b3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerifyUserDependency1ae953de4ac1a2a84a5dProvider(rootComponent: parent1(component) as! RootComponent)
}

#else
extension PullEventsComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\PullEventsDependency.userID] = "userID-UUID"
        keyPathToName[\PullEventsDependency.coreData] = "coreData-CoreDataStack"
        keyPathToName[\PullEventsDependency.cookieStorage] = "cookieStorage-any CookieStorageProtocol"
        keyPathToName[\PullEventsDependency.selectedAccount] = "selectedAccount-Account"
        keyPathToName[\PullEventsDependency.applicationContainer] = "applicationContainer-URL"
        keyPathToName[\PullEventsDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\PullEventsDependency.messageLocalStore] = "messageLocalStore-any MessageLocalStoreProtocol"
        keyPathToName[\PullEventsDependency.conversationLocalStore] = "conversationLocalStore-any ConversationLocalStoreProtocol"
        keyPathToName[\PullEventsDependency.userLocalStore] = "userLocalStore-any UserLocalStoreProtocol"

    }
}
extension GenerateNotificationComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\GenerateNotificationDependency.contentHandler] = "contentHandler-(UNNotificationContent) -> Void"
        keyPathToName[\GenerateNotificationDependency.messageLocalStore] = "messageLocalStore-any MessageLocalStoreProtocol"
        keyPathToName[\GenerateNotificationDependency.conversationLocalStore] = "conversationLocalStore-any ConversationLocalStoreProtocol"
        keyPathToName[\GenerateNotificationDependency.userLocalStore] = "userLocalStore-any UserLocalStoreProtocol"
    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["userID-UUID"] = { [unowned self] in self.userID as Any }
        localTable["applicationIdentifier-String"] = { [unowned self] in self.applicationIdentifier as Any }
        localTable["applicationContainer-URL"] = { [unowned self] in self.applicationContainer as Any }
        localTable["selectedAccount-Account"] = { [unowned self] in self.selectedAccount as Any }
        localTable["contentHandler-(UNNotificationContent) -> Void"] = { [unowned self] in self.contentHandler as Any }
    }
}
extension VerifyUserComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerifyUserDependency.userID] = "userID-UUID"
        keyPathToName[\VerifyUserDependency.selectedAccount] = "selectedAccount-Account"
        keyPathToName[\VerifyUserDependency.applicationIdentifier] = "applicationIdentifier-String"
        localTable["cookieStorage-any CookieStorageProtocol"] = { [unowned self] in self.cookieStorage as Any }
        localTable["userLocalStore-any UserLocalStoreProtocol"] = { [unowned self] in self.userLocalStore as Any }
        localTable["conversationLocalStore-any ConversationLocalStoreProtocol"] = { [unowned self] in self.conversationLocalStore as Any }
        localTable["messageLocalStore-any MessageLocalStoreProtocol"] = { [unowned self] in self.messageLocalStore as Any }
        localTable["coreData-CoreDataStack"] = { [unowned self] in self.coreData as Any }
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
    registerProviderFactory("^->RootComponent->VerifyUserComponent->PullEventsComponent", factoryb76115b3e674a8bbffc00e4ca4825856fdf1a57c)
    registerProviderFactory("^->RootComponent->VerifyUserComponent->PullEventsComponent->GenerateNotificationComponent", factoryfc879bce2c4eef2d1ee9b0226f348eb7db75c336)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->VerifyUserComponent", factoryd5eeee80e5892aa86d18b3a8f24c1d289f2c0f2e)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
