

import Foundation
import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
internal import WireAuthenticationCore
internal import WireAuthenticationUI

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

private class LandingComponentDependency653dae7d93b5cae880fbProvider: LandingComponentDependency {
    var router: Router {
        return rootComponent.router
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LandingComponent
private func factorybff3ded422912bdb9144b3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LandingComponentDependency653dae7d93b5cae880fbProvider(rootComponent: parent1(component) as! RootComponent)
}
private class LoginViaEmailComponentDependencyc2b347f4733021adfccfProvider: LoginViaEmailComponentDependency {
    var router: Router {
        return rootComponent.router
    }
    var networkService: NetworkService {
        return rootComponent.networkService
    }
    var apiVersion: APIVersion {
        return rootComponent.apiVersion
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LandingComponent->LoginViaEmailComponent
private func factoryacb5a0b942bf18b581a5a9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaEmailComponentDependencyc2b347f4733021adfccfProvider(rootComponent: parent2(component) as! RootComponent)
}
private class VerifyEmailComponentDependencyde4ea28a3da55436d1acProvider: VerifyEmailComponentDependency {
    var router: Router {
        return rootComponent.router
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LandingComponent->LoginViaEmailComponent->VerifyEmailComponent
private func factory7c5258aa95eabeebbea342f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerifyEmailComponentDependencyde4ea28a3da55436d1acProvider(rootComponent: parent3(component) as! RootComponent)
}

#else
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["apiVersion-APIVersion"] = { [unowned self] in self.apiVersion as Any }
        localTable["networkService-NetworkService"] = { [unowned self] in self.networkService as Any }
        localTable["router-Router"] = { [unowned self] in self.router as Any }
    }
}
extension LandingComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LandingComponentDependency.router] = "router-Router"

    }
}
extension LoginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailComponentDependency.router] = "router-Router"
        keyPathToName[\LoginViaEmailComponentDependency.networkService] = "networkService-NetworkService"
        keyPathToName[\LoginViaEmailComponentDependency.apiVersion] = "apiVersion-APIVersion"

    }
}
extension VerifyEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerifyEmailComponentDependency.router] = "router-Router"
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
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->LandingComponent", factorybff3ded422912bdb9144b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->LandingComponent->LoginViaEmailComponent", factoryacb5a0b942bf18b581a5a9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->LandingComponent->LoginViaEmailComponent->VerifyEmailComponent", factory7c5258aa95eabeebbea342f5655bf2362a8495f6)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
