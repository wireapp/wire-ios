

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
    registerProviderFactory("^->NSEFlow->NSEUserScope->NSEClientScope", factory757c2bbb6c9fac2078f23d42a6b301a1bd65d55f)
    registerProviderFactory("^->NSEFlow", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
