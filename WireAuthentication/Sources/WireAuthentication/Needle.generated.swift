

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

private func parent2(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent
}

private func parent3(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class LoginViaEmailOnPremComponentDependencyf7e724456bf0a882da0aProvider: LoginViaEmailOnPremComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var preferredAPIVersion: APIVersion? {
        return rootComponent.preferredAPIVersion
    }
    var minTLSVersion: TLSVersion {
        return rootComponent.minTLSVersion
    }
    var passwordValidator: any PasswordValidator {
        return rootComponent.passwordValidator
    }
    var appStoreURL: URL {
        return rootComponent.appStoreURL
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LoginViaEmailOnPremComponent
private func factory1ea11c5904a3248307ceb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaEmailOnPremComponentDependencyf7e724456bf0a882da0aProvider(rootComponent: parent1(component) as! RootComponent)
}
private class VerificationCodeComponentDependencyd02e826a878d23ff0224Provider: VerificationCodeComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol {
        return loginViaEmailComponent.loginViaEmailUseCase
    }
    var authenticationAPI: any AuthenticationAPI {
        return loginViaEmailComponent.authenticationAPI
    }
    var backendEnvironment: WireAuthenticationBackendEnvironment {
        return loginViaEmailComponent.backendEnvironment
    }
    private let loginViaEmailComponent: LoginViaEmailComponent
    private let rootComponent: RootComponent
    init(loginViaEmailComponent: LoginViaEmailComponent, rootComponent: RootComponent) {
        self.loginViaEmailComponent = loginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent->VerificationCodeComponent
private func factory455d456aa85e221de9f917031e1ba787d83cb463(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationCodeComponentDependencyd02e826a878d23ff0224Provider(loginViaEmailComponent: parent1(component) as! LoginViaEmailComponent, rootComponent: parent3(component) as! RootComponent)
}
private class SwitchBackendConfirmationComponentDependency46f0315d4d9444bb0013Provider: SwitchBackendConfirmationComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var preferredAPIVersion: APIVersion? {
        return rootComponent.preferredAPIVersion
    }
    var productionVersions: Set<APIVersion> {
        return rootComponent.productionVersions
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
    var appStoreURL: URL {
        return rootComponent.appStoreURL
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodOnPremComponent->SwitchBackendConfirmationComponent
private func factoryc3ca84fc11eaf902906ba9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SwitchBackendConfirmationComponentDependency46f0315d4d9444bb0013Provider(rootComponent: parent2(component) as! RootComponent)
}
private class LoginViaSSODependencyfcc94352e4288191cb45Provider: LoginViaSSODependency {
    var router: any Router {
        return rootComponent.router
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodOnPremComponent->SwitchBackendConfirmationComponent->LoginViaSSOComponent
private func factorya3c1ab8699ba4eca06cf42f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaSSODependencyfcc94352e4288191cb45Provider(rootComponent: parent3(component) as! RootComponent)
}
/// ^->RootComponent->LoginViaSSOComponent
private func factorya3c1ab8699ba4eca06cfb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaSSODependencyfcc94352e4288191cb45Provider(rootComponent: parent1(component) as! RootComponent)
}
/// ^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaSSOComponent
private func factorya3c1ab8699ba4eca06cfa9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaSSODependencyfcc94352e4288191cb45Provider(rootComponent: parent2(component) as! RootComponent)
}
private class NoHistoryComponentDependency0df6cc26e7db3dd9d951Provider: NoHistoryComponentDependency {
    var howToChangeEmailURL: URL {
        return rootComponent.howToChangeEmailURL
    }
    var howToDeleteAccountURL: URL {
        return rootComponent.howToDeleteAccountURL
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
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
private class DetermineAuthMethodOnPremComponentDependencyb4a02ddb77e5a66140fbProvider: DetermineAuthMethodOnPremComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    var preferredAPIVersion: APIVersion? {
        return rootComponent.preferredAPIVersion
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
    var appStoreURL: URL {
        return rootComponent.appStoreURL
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodOnPremComponent
private func factorydbdff85f3341dce5e925b3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return DetermineAuthMethodOnPremComponentDependencyb4a02ddb77e5a66140fbProvider(rootComponent: parent1(component) as! RootComponent)
}
private class LoginViaEmailComponentDependency02acc83f1ad8d17e18e1Provider: LoginViaEmailComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var accountsURL: URL {
        return rootComponent.accountsURL
    }
    var passwordValidator: any PasswordValidator {
        return rootComponent.passwordValidator
    }
    var networkService: NetworkService {
        return determineAuthMethodOnPremComponent.networkService
    }
    var environmentType: BackendEnvironmentType {
        return rootComponent.environmentType
    }
    var backendConfig: BackendConfig {
        return rootComponent.backendConfig
    }
    var minTLSVersion: TLSVersion {
        return rootComponent.minTLSVersion
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    private let determineAuthMethodOnPremComponent: DetermineAuthMethodOnPremComponent
    private let rootComponent: RootComponent
    init(determineAuthMethodOnPremComponent: DetermineAuthMethodOnPremComponent, rootComponent: RootComponent) {
        self.determineAuthMethodOnPremComponent = determineAuthMethodOnPremComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent
private func factoryf72dc3dd3ed336197337cd4281a5bfff6e29e9ef(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaEmailComponentDependency02acc83f1ad8d17e18e1Provider(determineAuthMethodOnPremComponent: parent1(component) as! DetermineAuthMethodOnPremComponent, rootComponent: parent2(component) as! RootComponent)
}

#else
extension LoginViaEmailOnPremComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailOnPremComponentDependency.router] = "router-any Router"
        keyPathToName[\LoginViaEmailOnPremComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\LoginViaEmailOnPremComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\LoginViaEmailOnPremComponentDependency.passwordValidator] = "passwordValidator-any PasswordValidator"
        keyPathToName[\LoginViaEmailOnPremComponentDependency.appStoreURL] = "appStoreURL-URL"
    }
}
extension VerificationCodeComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerificationCodeComponentDependency.router] = "router-any Router"
        keyPathToName[\VerificationCodeComponentDependency.loginViaEmailUseCase] = "loginViaEmailUseCase-any LoginViaEmailUseCaseProtocol"
        keyPathToName[\VerificationCodeComponentDependency.authenticationAPI] = "authenticationAPI-any AuthenticationAPI"
        keyPathToName[\VerificationCodeComponentDependency.backendEnvironment] = "backendEnvironment-WireAuthenticationBackendEnvironment"
    }
}
extension SwitchBackendConfirmationComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\SwitchBackendConfirmationComponentDependency.router] = "router-any Router"
        keyPathToName[\SwitchBackendConfirmationComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\SwitchBackendConfirmationComponentDependency.productionVersions] = "productionVersions-Set<APIVersion>"
        keyPathToName[\SwitchBackendConfirmationComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\SwitchBackendConfirmationComponentDependency.ssoCallbackURLScheme] = "ssoCallbackURLScheme-String"
        keyPathToName[\SwitchBackendConfirmationComponentDependency.userDefaults] = "userDefaults-UserDefaults"
        keyPathToName[\SwitchBackendConfirmationComponentDependency.appStoreURL] = "appStoreURL-URL"
        localTable["backendConfig-BackendConfig"] = { [unowned self] in self.backendConfig as Any }
    }
}
extension LoginViaSSOComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaSSODependency.router] = "router-any Router"
        keyPathToName[\LoginViaSSODependency.bridge] = "bridge-WireAuthenticationBridge"
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
        localTable["appStoreURL-URL"] = { [unowned self] in self.appStoreURL as Any }
        localTable["bridge-WireAuthenticationBridge"] = { [unowned self] in self.bridge as Any }
        localTable["router-any Router"] = { [unowned self] in self.router as Any }
    }
}
extension NoHistoryComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\NoHistoryComponentDependency.howToChangeEmailURL] = "howToChangeEmailURL-URL"
        keyPathToName[\NoHistoryComponentDependency.howToDeleteAccountURL] = "howToDeleteAccountURL-URL"
        keyPathToName[\NoHistoryComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
    }
}
extension DetermineAuthMethodOnPremComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.router] = "router-any Router"
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.ssoCallbackURLScheme] = "ssoCallbackURLScheme-String"
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.userDefaults] = "userDefaults-UserDefaults"
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.appStoreURL] = "appStoreURL-URL"
        localTable["networkService-NetworkService"] = { [unowned self] in self.networkService as Any }
    }
}
extension LoginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailComponentDependency.router] = "router-any Router"
        keyPathToName[\LoginViaEmailComponentDependency.accountsURL] = "accountsURL-URL"
        keyPathToName[\LoginViaEmailComponentDependency.passwordValidator] = "passwordValidator-any PasswordValidator"
        keyPathToName[\LoginViaEmailComponentDependency.networkService] = "networkService-NetworkService"
        keyPathToName[\LoginViaEmailComponentDependency.environmentType] = "environmentType-BackendEnvironmentType"
        keyPathToName[\LoginViaEmailComponentDependency.backendConfig] = "backendConfig-BackendConfig"
        keyPathToName[\LoginViaEmailComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\LoginViaEmailComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        localTable["authenticationAPI-any AuthenticationAPI"] = { [unowned self] in self.authenticationAPI as Any }
        localTable["loginViaEmailUseCase-any LoginViaEmailUseCaseProtocol"] = { [unowned self] in self.loginViaEmailUseCase as Any }
        localTable["backendEnvironment-WireAuthenticationBackendEnvironment"] = { [unowned self] in self.backendEnvironment as Any }
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
    registerProviderFactory("^->RootComponent->LoginViaEmailOnPremComponent", factory1ea11c5904a3248307ceb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent->VerificationCodeComponent", factory455d456aa85e221de9f917031e1ba787d83cb463)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->SwitchBackendConfirmationComponent", factoryc3ca84fc11eaf902906ba9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->SwitchBackendConfirmationComponent->LoginViaSSOComponent", factorya3c1ab8699ba4eca06cf42f5655bf2362a8495f6)
    registerProviderFactory("^->RootComponent->LoginViaSSOComponent", factorya3c1ab8699ba4eca06cfb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaSSOComponent", factorya3c1ab8699ba4eca06cfa9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->NoHistoryComponent", factory3bfed346df783964230ab3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent", factorydbdff85f3341dce5e925b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent", factoryf72dc3dd3ed336197337cd4281a5bfff6e29e9ef)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
