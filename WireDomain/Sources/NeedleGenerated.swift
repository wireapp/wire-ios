

import CoreData
import Foundation
import NeedleFoundation
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

private func parent4(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent
}

private func parent5(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class EnvironmentDependency387fee667d71719a0ca1Provider: EnvironmentDependency {
    var applicationIdentifier: String {
        return rootComponent.applicationIdentifier
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->APIComponent->EnvironmentComponent
private func factorycf77651f97e9afb25ff75245f15e7ddf9f8adb40(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EnvironmentDependency387fee667d71719a0ca1Provider(rootComponent: parent5(component) as! RootComponent)
}
private class LocalStoreDependency2ff0dbd93b34b2bc7f54Provider: LocalStoreDependency {
    var userIdentifier: UUID {
        return rootComponent.userIdentifier
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->LocalStoreComponent
private func factoryf9db81fe6fa8008f441942f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LocalStoreDependency2ff0dbd93b34b2bc7f54Provider(rootComponent: parent3(component) as! RootComponent)
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->LocalStoreComponent
private func factoryf9db81fe6fa8008f441921a9c45ed079aafca21f(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LocalStoreDependency2ff0dbd93b34b2bc7f54Provider(rootComponent: parent4(component) as! RootComponent)
}
private class CoreStorageDependencycbc32c33f0a53f38a599Provider: CoreStorageDependency {
    var selectedAccount: Account {
        return rootComponent.selectedAccount
    }
    var applicationContainer: URL {
        return rootComponent.applicationContainer
    }
    var applicationIdentifier: String {
        return rootComponent.applicationIdentifier
    }
    var userIdentifier: UUID {
        return rootComponent.userIdentifier
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->AuthenticationComponent->CoreStorageComponent
private func factory12f7ed8a55d8f76ae861a9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return CoreStorageDependencycbc32c33f0a53f38a599Provider(rootComponent: parent2(component) as! RootComponent)
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->CoreStorageComponent
private func factory12f7ed8a55d8f76ae86142f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return CoreStorageDependencycbc32c33f0a53f38a599Provider(rootComponent: parent3(component) as! RootComponent)
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->APIComponent->CoreStorageComponent
private func factory12f7ed8a55d8f76ae8615245f15e7ddf9f8adb40(_ component: NeedleFoundation.Scope) -> AnyObject {
    return CoreStorageDependencycbc32c33f0a53f38a599Provider(rootComponent: parent5(component) as! RootComponent)
}
private class CoreServiceDependency78456aa1cb483153746bProvider: CoreServiceDependency {
    var userIdentifier: UUID {
        return rootComponent.userIdentifier
    }
    var applicationContainer: URL {
        return rootComponent.applicationContainer
    }
    var applicationIdentifier: String {
        return rootComponent.applicationIdentifier
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->CoreServiceComponent
private func factorycb4ffa78e95857334d2142f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return CoreServiceDependency78456aa1cb483153746bProvider(rootComponent: parent3(component) as! RootComponent)
}
private class PullEventsSyncDependency9c514b897c25cc8dddddProvider: PullEventsSyncDependency {
    var userIdentifier: UUID {
        return rootComponent.userIdentifier
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent
private func factoryb0555b85879e31100a0642f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return PullEventsSyncDependency9c514b897c25cc8dddddProvider(rootComponent: parent3(component) as! RootComponent)
}

#else
extension AuthenticationComponent: NeedleFoundation.Registration {
    public func registerItems() {


    }
}
extension EnvironmentComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\EnvironmentDependency.applicationIdentifier] = "applicationIdentifier-String"
    }
}
extension LocalStoreComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LocalStoreDependency.userIdentifier] = "userIdentifier-UUID"
    }
}
extension AuthenticatedComponent: NeedleFoundation.Registration {
    public func registerItems() {


    }
}
extension CoreStorageComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\CoreStorageDependency.selectedAccount] = "selectedAccount-Account"
        keyPathToName[\CoreStorageDependency.applicationContainer] = "applicationContainer-URL"
        keyPathToName[\CoreStorageDependency.applicationIdentifier] = "applicationIdentifier-String"
        keyPathToName[\CoreStorageDependency.userIdentifier] = "userIdentifier-UUID"
    }
}
extension CoreServiceComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\CoreServiceDependency.userIdentifier] = "userIdentifier-UUID"
        keyPathToName[\CoreServiceDependency.applicationContainer] = "applicationContainer-URL"
        keyPathToName[\CoreServiceDependency.applicationIdentifier] = "applicationIdentifier-String"
    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["userIdentifier-UUID"] = { [unowned self] in self.userIdentifier as Any }
        localTable["applicationIdentifier-String"] = { [unowned self] in self.applicationIdentifier as Any }
        localTable["applicationContainer-URL"] = { [unowned self] in self.applicationContainer as Any }
        localTable["selectedAccount-Account"] = { [unowned self] in self.selectedAccount as Any }
    }
}
extension SyncComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\PullEventsSyncDependency.userIdentifier] = "userIdentifier-UUID"

    }
}
extension APIComponent: NeedleFoundation.Registration {
    public func registerItems() {


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
    registerProviderFactory("^->RootComponent->AuthenticationComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->APIComponent->EnvironmentComponent", factorycf77651f97e9afb25ff75245f15e7ddf9f8adb40)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->LocalStoreComponent", factoryf9db81fe6fa8008f441942f5655bf2362a8495f6)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->LocalStoreComponent", factoryf9db81fe6fa8008f441921a9c45ed079aafca21f)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->CoreStorageComponent", factory12f7ed8a55d8f76ae861a9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->CoreStorageComponent", factory12f7ed8a55d8f76ae86142f5655bf2362a8495f6)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->APIComponent->CoreStorageComponent", factory12f7ed8a55d8f76ae8615245f15e7ddf9f8adb40)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->CoreServiceComponent", factorycb4ffa78e95857334d2142f5655bf2362a8495f6)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent", factoryb0555b85879e31100a0642f5655bf2362a8495f6)
    registerProviderFactory("^->RootComponent->AuthenticationComponent->AuthenticatedComponent->SyncComponent->APIComponent", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
