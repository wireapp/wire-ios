

import Foundation
import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
import WireLogging
import WireReusableUIComponents
internal import WireAuthenticationLogic
internal import WireAuthenticationUI

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class DetermineAuthMethodComponentDependency527e70b5dbcfcb8f2023Provider: DetermineAuthMethodComponentDependency {


    init() {

    }
}
/// ^->RootComponent->DetermineAuthMethodComponent
private func factoryd47fa74281e135cd9f10e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return DetermineAuthMethodComponentDependency527e70b5dbcfcb8f2023Provider()
}
private class SwitchBackendConfirmationComponentDependency7a1956d88810c08ef169Provider: SwitchBackendConfirmationComponentDependency {


    init() {

    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->SwitchBackendConfirmationComponent
private func factorye1144df20d596f07c3bee3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SwitchBackendConfirmationComponentDependency7a1956d88810c08ef169Provider()
}
private class LoginViaSSODependencycb22423a897409b8b5faProvider: LoginViaSSODependency {


    init() {

    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaSSOComponent
private func factory075263b25e612b6948d3e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaSSODependencycb22423a897409b8b5faProvider()
}

#else
extension DetermineAuthMethodComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["networkService-any NetworkServiceProtocol"] = { [unowned self] in self.networkService as Any }
    }
}
extension SwitchBackendConfirmationComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension LoginViaSSOComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["environmentType-BackendEnvironmentType"] = { [unowned self] in self.environmentType as Any }
        localTable["backendConfig-BackendConfig"] = { [unowned self] in self.backendConfig as Any }
        localTable["preferredAPIVersion-APIVersion?"] = { [unowned self] in self.preferredAPIVersion as Any }
        localTable["productionVersions-Set<APIVersion>"] = { [unowned self] in self.productionVersions as Any }
        localTable["minTLSVersion-TLSVersion"] = { [unowned self] in self.minTLSVersion as Any }
        localTable["accountsURL-URL"] = { [unowned self] in self.accountsURL as Any }
        localTable["howToChangeEmailURL-URL"] = { [unowned self] in self.howToChangeEmailURL as Any }
        localTable["howToDeleteAccountURL-URL"] = { [unowned self] in self.howToDeleteAccountURL as Any }
        localTable["passwordValidator-any PasswordValidator"] = { [unowned self] in self.passwordValidator as Any }
        localTable["ssoCallbackURLScheme-String"] = { [unowned self] in self.ssoCallbackURLScheme as Any }
        localTable["userDefaults-UserDefaults"] = { [unowned self] in self.userDefaults as Any }
        localTable["onRegisterAccount-() -> Void"] = { [unowned self] in self.onRegisterAccount as Any }
        localTable["bridge-WireAuthenticationBridge"] = { [unowned self] in self.bridge as Any }
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
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent", factoryd47fa74281e135cd9f10e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->SwitchBackendConfirmationComponent", factorye1144df20d596f07c3bee3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaSSOComponent", factory075263b25e612b6948d3e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
