

import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
import WireReusableUIComponents
internal import WireAuthenticationLogic
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

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class VerificationCodeComponentDependency48f3b80358781bc7c928Provider: VerificationCodeComponentDependency {


    init() {

    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent
private func factoryd3638676a47fce1fe623e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationCodeComponentDependency48f3b80358781bc7c928Provider()
}
private class DetermineAuthMethodComponentDependency527e70b5dbcfcb8f2023Provider: DetermineAuthMethodComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var defaultBackendEnvironment: BackendEnvironment {
        return rootComponent.defaultBackendEnvironment
    }
    var defaultAPIVersion: APIVersion {
        return rootComponent.defaultAPIVersion
    }
    var minTLSVersion: TLSVersion {
        return rootComponent.minTLSVersion
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent
private func factoryd47fa74281e135cd9f10b3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return DetermineAuthMethodComponentDependency527e70b5dbcfcb8f2023Provider(rootComponent: parent1(component) as! RootComponent)
}
private class LoginViaEmailComponentDependency6f812ea9ca4f0322dd27Provider: LoginViaEmailComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var accountsURL: URL {
        return rootComponent.accountsURL
    }
    var passwordValidator: any PasswordValidator {
        return rootComponent.passwordValidator
    }
    var authenticationAPI: AuthenticationAPI {
        return determineAuthMethodComponent.authenticationAPI
    }
    private let determineAuthMethodComponent: DetermineAuthMethodComponent
    private let rootComponent: RootComponent
    init(determineAuthMethodComponent: DetermineAuthMethodComponent, rootComponent: RootComponent) {
        self.determineAuthMethodComponent = determineAuthMethodComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent
private func factory9bda312c16141c932061c770221f242f9204cf85(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaEmailComponentDependency6f812ea9ca4f0322dd27Provider(determineAuthMethodComponent: parent1(component) as! DetermineAuthMethodComponent, rootComponent: parent2(component) as! RootComponent)
}

#else
extension VerificationCodeComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension DetermineAuthMethodComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\DetermineAuthMethodComponentDependency.router] = "router-any Router"
        keyPathToName[\DetermineAuthMethodComponentDependency.defaultBackendEnvironment] = "defaultBackendEnvironment-BackendEnvironment"
        keyPathToName[\DetermineAuthMethodComponentDependency.defaultAPIVersion] = "defaultAPIVersion-APIVersion"
        keyPathToName[\DetermineAuthMethodComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        localTable["authenticationAPI-AuthenticationAPI"] = { [unowned self] in self.authenticationAPI as Any }
    }
}
extension LoginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailComponentDependency.router] = "router-any Router"
        keyPathToName[\LoginViaEmailComponentDependency.accountsURL] = "accountsURL-URL"
        keyPathToName[\LoginViaEmailComponentDependency.passwordValidator] = "passwordValidator-any PasswordValidator"
        keyPathToName[\LoginViaEmailComponentDependency.authenticationAPI] = "authenticationAPI-AuthenticationAPI"

    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["defaultBackendEnvironment-BackendEnvironment"] = { [unowned self] in self.defaultBackendEnvironment as Any }
        localTable["defaultAPIVersion-APIVersion"] = { [unowned self] in self.defaultAPIVersion as Any }
        localTable["minTLSVersion-TLSVersion"] = { [unowned self] in self.minTLSVersion as Any }
        localTable["accountsURL-URL"] = { [unowned self] in self.accountsURL as Any }
        localTable["passwordValidator-any PasswordValidator"] = { [unowned self] in self.passwordValidator as Any }
        localTable["router-any Router"] = { [unowned self] in self.router as Any }
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
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent", factoryd3638676a47fce1fe623e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent", factoryd47fa74281e135cd9f10b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent", factory9bda312c16141c932061c770221f242f9204cf85)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
