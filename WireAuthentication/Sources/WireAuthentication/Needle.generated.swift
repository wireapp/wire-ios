

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

private func parent3(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class VerificationCodeComponentDependency48f3b80358781bc7c928Provider: VerificationCodeComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol {
        return loginViaEmailComponent.loginViaEmailUseCase
    }
    var authenticationAPI: AuthenticationAPI {
        return determineAuthMethodComponent.authenticationAPI
    }
    private let determineAuthMethodComponent: DetermineAuthMethodComponent
    private let loginViaEmailComponent: LoginViaEmailComponent
    private let rootComponent: RootComponent
    init(determineAuthMethodComponent: DetermineAuthMethodComponent, loginViaEmailComponent: LoginViaEmailComponent, rootComponent: RootComponent) {
        self.determineAuthMethodComponent = determineAuthMethodComponent
        self.loginViaEmailComponent = loginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent
private func factoryd3638676a47fce1fe623cded1e126cd6f1df3cee(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationCodeComponentDependency48f3b80358781bc7c928Provider(determineAuthMethodComponent: parent2(component) as! DetermineAuthMethodComponent, loginViaEmailComponent: parent1(component) as! LoginViaEmailComponent, rootComponent: parent3(component) as! RootComponent)
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
    var ssoCallbackURLScheme: String {
        return rootComponent.ssoCallbackURLScheme
    }
    var userDefaults: UserDefaults {
        return rootComponent.userDefaults
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
private class NoHistoryComponentDependency0df6cc26e7db3dd9d951Provider: NoHistoryComponentDependency {
    var howToChangeEmailURL: URL {
        return rootComponent.howToChangeEmailURL
    }
    var howToDeleteAccountURL: URL {
        return rootComponent.howToDeleteAccountURL
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->NoHistoryComponent
private func factory3bfed346df783964230ab3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependency0df6cc26e7db3dd9d951Provider(rootComponent: parent1(component) as! RootComponent)
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
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
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
        keyPathToName[\VerificationCodeComponentDependency.router] = "router-any Router"
        keyPathToName[\VerificationCodeComponentDependency.loginViaEmailUseCase] = "loginViaEmailUseCase-any LoginViaEmailUseCaseProtocol"
        keyPathToName[\VerificationCodeComponentDependency.authenticationAPI] = "authenticationAPI-AuthenticationAPI"
    }
}
extension DetermineAuthMethodComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\DetermineAuthMethodComponentDependency.router] = "router-any Router"
        keyPathToName[\DetermineAuthMethodComponentDependency.defaultBackendEnvironment] = "defaultBackendEnvironment-BackendEnvironment"
        keyPathToName[\DetermineAuthMethodComponentDependency.defaultAPIVersion] = "defaultAPIVersion-APIVersion"
        keyPathToName[\DetermineAuthMethodComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\DetermineAuthMethodComponentDependency.ssoCallbackURLScheme] = "ssoCallbackURLScheme-String"
        keyPathToName[\DetermineAuthMethodComponentDependency.userDefaults] = "userDefaults-UserDefaults"
        localTable["authenticationAPI-AuthenticationAPI"] = { [unowned self] in self.authenticationAPI as Any }
    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["defaultBackendEnvironment-BackendEnvironment"] = { [unowned self] in self.defaultBackendEnvironment as Any }
        localTable["defaultAPIVersion-APIVersion"] = { [unowned self] in self.defaultAPIVersion as Any }
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
extension NoHistoryComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\NoHistoryComponentDependency.howToChangeEmailURL] = "howToChangeEmailURL-URL"
        keyPathToName[\NoHistoryComponentDependency.howToDeleteAccountURL] = "howToDeleteAccountURL-URL"
    }
}
extension LoginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailComponentDependency.router] = "router-any Router"
        keyPathToName[\LoginViaEmailComponentDependency.accountsURL] = "accountsURL-URL"
        keyPathToName[\LoginViaEmailComponentDependency.passwordValidator] = "passwordValidator-any PasswordValidator"
        keyPathToName[\LoginViaEmailComponentDependency.authenticationAPI] = "authenticationAPI-AuthenticationAPI"
        keyPathToName[\LoginViaEmailComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        localTable["loginViaEmailUseCase-any LoginViaEmailUseCaseProtocol"] = { [unowned self] in self.loginViaEmailUseCase as Any }
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
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent", factoryd3638676a47fce1fe623cded1e126cd6f1df3cee)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent", factoryd47fa74281e135cd9f10b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->NoHistoryComponent", factory3bfed346df783964230ab3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent", factory9bda312c16141c932061c770221f242f9204cf85)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
