

import Foundation
import NeedleFoundation
import UserNotifications
import WireCrypto
import WireDataModel
import WireFoundation
import WireLogging
import WireNetwork

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

private class NSEUserScopeDependency2c7b3df7f8cb346a36faProvider: NSEUserScopeDependency {
    var currentBuildNumber: String {
        return nSEFlow.currentBuildNumber
    }
    var appContainerURL: URL {
        return nSEFlow.appContainerURL
    }
    var accountDataURL: URL {
        return nSEFlow.accountDataURL
    }
    var backendStore: BackendEnvironmentStore {
        return nSEFlow.backendStore
    }
    var sharedUserDefaults: UserDefaults {
        return nSEFlow.sharedUserDefaults
    }
    var cookieEncryptionKey: Data {
        return nSEFlow.cookieEncryptionKey
    }
    var minTLSVersion: WireNetwork.TLSVersion {
        return nSEFlow.minTLSVersion
    }
    var preferredAPIVersion: WireNetwork.APIVersion? {
        return nSEFlow.preferredAPIVersion
    }
    private let nSEFlow: NSEFlow
    init(nSEFlow: NSEFlow) {
        self.nSEFlow = nSEFlow
    }
}
/// ^->NSEFlow->NSEUserScope
private func factorye08b4393f47288b9e50e5fbe4b399b025b29f502(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NSEUserScopeDependency2c7b3df7f8cb346a36faProvider(nSEFlow: parent1(component) as! NSEFlow)
}
private class ShowNotificationDependencya0b9d9633053c7a7a814Provider: ShowNotificationDependency {
    var contentHandler: (UNNotificationContent) -> Void {
        return notificationServiceExtensionFlow.contentHandler
    }
    var accountManager: AccountManager {
        return verifyUserStep.accountManager
    }
    var selectedAccount: Account {
        return verifyUserStep.selectedAccount
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return pullEventsStep.conversationLocalStore
    }
    var databaseSaver: any DatabaseSaverProtocol {
        return pullEventsStep.databaseSaver
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    private let pullEventsStep: PullEventsStep
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, pullEventsStep: PullEventsStep, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.pullEventsStep = pullEventsStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep->ShowNotificationStep
private func factory7cf4b2b30a4398b50d11a9cc2ff26e57789f8e96(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ShowNotificationDependencya0b9d9633053c7a7a814Provider(notificationServiceExtensionFlow: parent5(component) as! NotificationServiceExtensionFlow, pullEventsStep: parent2(component) as! PullEventsStep, verifyUserStep: parent3(component) as! VerifyUserStep)
}
private class ShowNotificationDependencyb76cdacc5a4451852f7dProvider: ShowNotificationDependency {
    var contentHandler: (UNNotificationContent) -> Void {
        return notificationServiceExtensionFlow.contentHandler
    }
    var accountManager: AccountManager {
        return verifyUserStep.accountManager
    }
    var selectedAccount: Account {
        return verifyUserStep.selectedAccount
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return syncEventsStep.conversationLocalStore
    }
    var databaseSaver: any DatabaseSaverProtocol {
        return syncEventsStep.databaseSaver
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    private let syncEventsStep: SyncEventsStep
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, syncEventsStep: SyncEventsStep, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.syncEventsStep = syncEventsStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->SyncEventsStep->GenerateNotificationStep->ShowNotificationStep
private func factorydb9c02c13ed8a3b4c57b2078b7cb922213bab1d6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ShowNotificationDependencyb76cdacc5a4451852f7dProvider(notificationServiceExtensionFlow: parent5(component) as! NotificationServiceExtensionFlow, syncEventsStep: parent2(component) as! SyncEventsStep, verifyUserStep: parent3(component) as! VerifyUserStep)
}
private class ProcessNotificationRequestDependency40b6d936f379fb50f3b3Provider: ProcessNotificationRequestDependency {
    var currentAppVersion: String {
        return notificationServiceExtensionFlow.currentAppVersion
    }
    var applicationContainer: URL {
        return notificationServiceExtensionFlow.applicationContainer
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep
private func factory57c45e6a5f7157fd1d7682b820770cde9bb5e257(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ProcessNotificationRequestDependency40b6d936f379fb50f3b3Provider(notificationServiceExtensionFlow: parent1(component) as! NotificationServiceExtensionFlow)
}
private class VerifyUserDependency86e4082a5d4cc2c665ceProvider: VerifyUserDependency {
    var applicationIdentifier: String {
        return notificationServiceExtensionFlow.applicationIdentifier
    }
    var applicationContainer: URL {
        return notificationServiceExtensionFlow.applicationContainer
    }
    private let notificationServiceExtensionFlow: NotificationServiceExtensionFlow
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep
private func factory1e6574088fa77c7ec1b3d4de722f9e5dfe8415c1(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerifyUserDependency86e4082a5d4cc2c665ceProvider(notificationServiceExtensionFlow: parent2(component) as! NotificationServiceExtensionFlow)
}
private class GenerateNotificationDependencye9ac54a4aea693448fe3Provider: GenerateNotificationDependency {
    var sharedUserDefaults: UserDefaults {
        return verifyUserStep.sharedUserDefaults
    }
    var userID: UUID {
        return verifyUserStep.userID
    }
    var eventID: UUID {
        return verifyUserStep.eventID
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return verifyUserStep.messageLocalStore
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return pullEventsStep.conversationLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return verifyUserStep.userLocalStore
    }
    private let pullEventsStep: PullEventsStep
    private let verifyUserStep: VerifyUserStep
    init(pullEventsStep: PullEventsStep, verifyUserStep: VerifyUserStep) {
        self.pullEventsStep = pullEventsStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep
private func factoryce7e84dac24eba2dbd0b06f68a2754112dcc40ad(_ component: NeedleFoundation.Scope) -> AnyObject {
    return GenerateNotificationDependencye9ac54a4aea693448fe3Provider(pullEventsStep: parent1(component) as! PullEventsStep, verifyUserStep: parent2(component) as! VerifyUserStep)
}
private class GenerateNotificationDependency234c6a5b34945316dab6Provider: GenerateNotificationDependency {
    var sharedUserDefaults: UserDefaults {
        return verifyUserStep.sharedUserDefaults
    }
    var userID: UUID {
        return verifyUserStep.userID
    }
    var eventID: UUID {
        return verifyUserStep.eventID
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return verifyUserStep.messageLocalStore
    }
    var conversationLocalStore: any ConversationLocalStoreProtocol {
        return syncEventsStep.conversationLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return verifyUserStep.userLocalStore
    }
    private let syncEventsStep: SyncEventsStep
    private let verifyUserStep: VerifyUserStep
    init(syncEventsStep: SyncEventsStep, verifyUserStep: VerifyUserStep) {
        self.syncEventsStep = syncEventsStep
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->SyncEventsStep->GenerateNotificationStep
private func factory8bf9ed88aea0f8f2db04f61d9dbc793922f9b297(_ component: NeedleFoundation.Scope) -> AnyObject {
    return GenerateNotificationDependency234c6a5b34945316dab6Provider(syncEventsStep: parent1(component) as! SyncEventsStep, verifyUserStep: parent2(component) as! VerifyUserStep)
}
private class PullEventsDependency53707bfe7fe589fd7ad1Provider: PullEventsDependency {
    var userID: UUID {
        return verifyUserStep.userID
    }
    var coreData: CoreDataStack {
        return verifyUserStep.coreData
    }
    var cookieStorage: any CookieStorageProtocol {
        return verifyUserStep.cookieStorage
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return verifyUserStep.messageLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return verifyUserStep.userLocalStore
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
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep
private func factoryf4ab58fd6d9a40f320668be8429a6bc7b371557e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return PullEventsDependency53707bfe7fe589fd7ad1Provider(notificationServiceExtensionFlow: parent3(component) as! NotificationServiceExtensionFlow, verifyUserStep: parent1(component) as! VerifyUserStep)
}
private class SyncEventsDependencyac60bf06509cd2e7559bProvider: SyncEventsDependency {
    var userID: UUID {
        return verifyUserStep.userID
    }
    var coreData: CoreDataStack {
        return verifyUserStep.coreData
    }
    var cookieStorage: any CookieStorageProtocol {
        return verifyUserStep.cookieStorage
    }
    var messageLocalStore: any MessageLocalStoreProtocol {
        return verifyUserStep.messageLocalStore
    }
    var userLocalStore: any UserLocalStoreProtocol {
        return verifyUserStep.userLocalStore
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
    private let verifyUserStep: VerifyUserStep
    init(notificationServiceExtensionFlow: NotificationServiceExtensionFlow, verifyUserStep: VerifyUserStep) {
        self.notificationServiceExtensionFlow = notificationServiceExtensionFlow
        self.verifyUserStep = verifyUserStep
    }
}
/// ^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->SyncEventsStep
private func factory69e893d5271726f7cf598be8429a6bc7b371557e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SyncEventsDependencyac60bf06509cd2e7559bProvider(notificationServiceExtensionFlow: parent3(component) as! NotificationServiceExtensionFlow, verifyUserStep: parent1(component) as! VerifyUserStep)
}
private class NSEClientScopeDependencyfc368141c1425b82ae14Provider: NSEClientScopeDependency {
    var account: Account {
        return nSEUserScope.account
    }
    var accountID: UUID {
        return nSEUserScope.accountID
    }
    var appContainerURL: URL {
        return nSEFlow.appContainerURL
    }
    var userAccountDataURL: URL {
        return nSEUserScope.userAccountDataURL
    }
    var accountManager: AccountManager {
        return nSEFlow.accountManager
    }
    var journal: Journal {
        return nSEUserScope.journal
    }
    var sharedUserDefaults: UserDefaults {
        return nSEFlow.sharedUserDefaults
    }
    var cookieStorage: CookieStorage {
        return nSEUserScope.cookieStorage
    }
    private let nSEFlow: NSEFlow
    private let nSEUserScope: NSEUserScope
    init(nSEFlow: NSEFlow, nSEUserScope: NSEUserScope) {
        self.nSEFlow = nSEFlow
        self.nSEUserScope = nSEUserScope
    }
}
/// ^->NSEFlow->NSEUserScope->NSEClientScope
private func factory757c2bbb6c9fac2078f23d42a6b301a1bd65d55f(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NSEClientScopeDependencyfc368141c1425b82ae14Provider(nSEFlow: parent2(component) as! NSEFlow, nSEUserScope: parent1(component) as! NSEUserScope)
}

#else
extension NSEUserScope: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\NSEUserScopeDependency.currentBuildNumber] = "currentBuildNumber-String"
        keyPathToName[\NSEUserScopeDependency.appContainerURL] = "appContainerURL-URL"
        keyPathToName[\NSEUserScopeDependency.accountDataURL] = "accountDataURL-URL"
        keyPathToName[\NSEUserScopeDependency.backendStore] = "backendStore-BackendEnvironmentStore"
        keyPathToName[\NSEUserScopeDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        keyPathToName[\NSEUserScopeDependency.cookieEncryptionKey] = "cookieEncryptionKey-Data"
        keyPathToName[\NSEUserScopeDependency.minTLSVersion] = "minTLSVersion-WireNetwork.TLSVersion"
        keyPathToName[\NSEUserScopeDependency.preferredAPIVersion] = "preferredAPIVersion-WireNetwork.APIVersion?"
        localTable["account-Account"] = { [unowned self] in self.account as Any }
        localTable["accountID-UUID"] = { [unowned self] in self.accountID as Any }
        localTable["userAccountDataURL-URL"] = { [unowned self] in self.userAccountDataURL as Any }
        localTable["journal-Journal"] = { [unowned self] in self.journal as Any }
        localTable["cookieStorage-CookieStorage"] = { [unowned self] in self.cookieStorage as Any }
    }
}
extension ShowNotificationStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\ShowNotificationDependency.contentHandler] = "contentHandler-(UNNotificationContent) -> Void"
        keyPathToName[\ShowNotificationDependency.accountManager] = "accountManager-AccountManager"
        keyPathToName[\ShowNotificationDependency.selectedAccount] = "selectedAccount-Account"
        keyPathToName[\ShowNotificationDependency.conversationLocalStore] = "conversationLocalStore-any ConversationLocalStoreProtocol"
        keyPathToName[\ShowNotificationDependency.databaseSaver] = "databaseSaver-any DatabaseSaverProtocol"
    }
}
extension ProcessNotificationRequestStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\ProcessNotificationRequestDependency.currentAppVersion] = "currentAppVersion-String"
        keyPathToName[\ProcessNotificationRequestDependency.applicationContainer] = "applicationContainer-URL"

    }
}
extension VerifyUserStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerifyUserDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\VerifyUserDependency.applicationContainer] = "applicationContainer-URL"
        localTable["selectedAccount-Account"] = { [unowned self] in self.selectedAccount as Any }
        localTable["accountManager-AccountManager"] = { [unowned self] in self.accountManager as Any }
        localTable["userID-UUID"] = { [unowned self] in self.userID as Any }
        localTable["eventID-UUID"] = { [unowned self] in self.eventID as Any }
        localTable["sharedUserDefaults-UserDefaults"] = { [unowned self] in self.sharedUserDefaults as Any }
        localTable["cookieStorage-any CookieStorageProtocol"] = { [unowned self] in self.cookieStorage as Any }
        localTable["coreData-CoreDataStack"] = { [unowned self] in self.coreData as Any }
        localTable["userLocalStore-any UserLocalStoreProtocol"] = { [unowned self] in self.userLocalStore as Any }
        localTable["messageLocalStore-any MessageLocalStoreProtocol"] = { [unowned self] in self.messageLocalStore as Any }
    }
}
extension NotificationServiceExtensionFlow: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["contentHandler-(UNNotificationContent) -> Void"] = { [unowned self] in self.contentHandler as Any }
        localTable["currentAppVersion-String"] = { [unowned self] in self.currentAppVersion as Any }
        localTable["applicationIdentifier-String"] = { [unowned self] in self.applicationIdentifier as Any }
        localTable["applicationContainer-URL"] = { [unowned self] in self.applicationContainer as Any }
    }
}
extension GenerateNotificationStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\GenerateNotificationDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        keyPathToName[\GenerateNotificationDependency.userID] = "userID-UUID"
        keyPathToName[\GenerateNotificationDependency.eventID] = "eventID-UUID"
        keyPathToName[\GenerateNotificationDependency.messageLocalStore] = "messageLocalStore-any MessageLocalStoreProtocol"
        keyPathToName[\GenerateNotificationDependency.conversationLocalStore] = "conversationLocalStore-any ConversationLocalStoreProtocol"
        keyPathToName[\GenerateNotificationDependency.userLocalStore] = "userLocalStore-any UserLocalStoreProtocol"

    }
}
extension PullEventsStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\PullEventsDependency.userID] = "userID-UUID"
        keyPathToName[\PullEventsDependency.coreData] = "coreData-CoreDataStack"
        keyPathToName[\PullEventsDependency.cookieStorage] = "cookieStorage-any CookieStorageProtocol"
        keyPathToName[\PullEventsDependency.messageLocalStore] = "messageLocalStore-any MessageLocalStoreProtocol"
        keyPathToName[\PullEventsDependency.userLocalStore] = "userLocalStore-any UserLocalStoreProtocol"
        keyPathToName[\PullEventsDependency.applicationContainer] = "applicationContainer-URL"
        keyPathToName[\PullEventsDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\PullEventsDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        localTable["conversationLocalStore-any ConversationLocalStoreProtocol"] = { [unowned self] in self.conversationLocalStore as Any }
        localTable["databaseSaver-any DatabaseSaverProtocol"] = { [unowned self] in self.databaseSaver as Any }
    }
}
extension SyncEventsStep: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\SyncEventsDependency.userID] = "userID-UUID"
        keyPathToName[\SyncEventsDependency.coreData] = "coreData-CoreDataStack"
        keyPathToName[\SyncEventsDependency.cookieStorage] = "cookieStorage-any CookieStorageProtocol"
        keyPathToName[\SyncEventsDependency.messageLocalStore] = "messageLocalStore-any MessageLocalStoreProtocol"
        keyPathToName[\SyncEventsDependency.userLocalStore] = "userLocalStore-any UserLocalStoreProtocol"
        keyPathToName[\SyncEventsDependency.applicationContainer] = "applicationContainer-URL"
        keyPathToName[\SyncEventsDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\SyncEventsDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        localTable["pushChannelAPI-any PushChannelV2API"] = { [unowned self] in self.pushChannelAPI as Any }
        localTable["conversationLocalStore-any ConversationLocalStoreProtocol"] = { [unowned self] in self.conversationLocalStore as Any }
        localTable["databaseSaver-any DatabaseSaverProtocol"] = { [unowned self] in self.databaseSaver as Any }
    }
}
extension NSEClientScope: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\NSEClientScopeDependency.account] = "account-Account"
        keyPathToName[\NSEClientScopeDependency.accountID] = "accountID-UUID"
        keyPathToName[\NSEClientScopeDependency.appContainerURL] = "appContainerURL-URL"
        keyPathToName[\NSEClientScopeDependency.userAccountDataURL] = "userAccountDataURL-URL"
        keyPathToName[\NSEClientScopeDependency.accountManager] = "accountManager-AccountManager"
        keyPathToName[\NSEClientScopeDependency.journal] = "journal-Journal"
        keyPathToName[\NSEClientScopeDependency.sharedUserDefaults] = "sharedUserDefaults-UserDefaults"
        keyPathToName[\NSEClientScopeDependency.cookieStorage] = "cookieStorage-CookieStorage"
    }
}
extension NSEFlow: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["currentBuildNumber-String"] = { [unowned self] in self.currentBuildNumber as Any }
        localTable["appContainerURL-URL"] = { [unowned self] in self.appContainerURL as Any }
        localTable["accountDataURL-URL"] = { [unowned self] in self.accountDataURL as Any }
        localTable["accountManager-AccountManager"] = { [unowned self] in self.accountManager as Any }
        localTable["backendStore-BackendEnvironmentStore"] = { [unowned self] in self.backendStore as Any }
        localTable["sharedUserDefaults-UserDefaults"] = { [unowned self] in self.sharedUserDefaults as Any }
        localTable["cookieEncryptionKey-Data"] = { [unowned self] in self.cookieEncryptionKey as Any }
        localTable["minTLSVersion-WireNetwork.TLSVersion"] = { [unowned self] in self.minTLSVersion as Any }
        localTable["preferredAPIVersion-WireNetwork.APIVersion?"] = { [unowned self] in self.preferredAPIVersion as Any }
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
    registerProviderFactory("^->NSEFlow->NSEUserScope", factorye08b4393f47288b9e50e5fbe4b399b025b29f502)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep->ShowNotificationStep", factory7cf4b2b30a4398b50d11a9cc2ff26e57789f8e96)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->SyncEventsStep->GenerateNotificationStep->ShowNotificationStep", factorydb9c02c13ed8a3b4c57b2078b7cb922213bab1d6)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep", factory57c45e6a5f7157fd1d7682b820770cde9bb5e257)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep", factory1e6574088fa77c7ec1b3d4de722f9e5dfe8415c1)
    registerProviderFactory("^->NotificationServiceExtensionFlow", factoryEmptyDependencyProvider)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep->GenerateNotificationStep", factoryce7e84dac24eba2dbd0b06f68a2754112dcc40ad)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->SyncEventsStep->GenerateNotificationStep", factory8bf9ed88aea0f8f2db04f61d9dbc793922f9b297)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->PullEventsStep", factoryf4ab58fd6d9a40f320668be8429a6bc7b371557e)
    registerProviderFactory("^->NotificationServiceExtensionFlow->ProcessNotificationRequestStep->VerifyUserStep->SyncEventsStep", factory69e893d5271726f7cf598be8429a6bc7b371557e)
    registerProviderFactory("^->NSEFlow->NSEUserScope->NSEClientScope", factory757c2bbb6c9fac2078f23d42a6b301a1bd65d55f)
    registerProviderFactory("^->NSEFlow", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
