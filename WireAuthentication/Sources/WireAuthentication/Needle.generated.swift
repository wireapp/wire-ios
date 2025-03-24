

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

private func parent4(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent
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
    var authenticationAPI: any AuthenticationAPI {
        return loginViaEmailComponent.authenticationAPI
    }
    var backendEnvironment: WireAuthenticationBackendEnvironment {
        return loginViaEmailComponent.backendEnvironment
    }
    var networkStack: NetworkStack {
        return loginViaEmailComponent.networkStack
    }
    var didDetectDomainConflict: Bool {
        return loginViaEmailComponent.didDetectDomainConflict
    }
    private let loginViaEmailComponent: LoginViaEmailComponent
    private let rootComponent: RootComponent
    init(loginViaEmailComponent: LoginViaEmailComponent, rootComponent: RootComponent) {
        self.loginViaEmailComponent = loginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent
private func factoryd3638676a47fce1fe62317031e1ba787d83cb463(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationCodeComponentDependency48f3b80358781bc7c928Provider(loginViaEmailComponent: parent1(component) as! LoginViaEmailComponent, rootComponent: parent3(component) as! RootComponent)
}
/// ^->RootComponent->LoginViaEmailComponent->VerificationCodeComponent
private func factoryd3638676a47fce1fe623a054ff50c10da855de8a(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationCodeComponentDependency48f3b80358781bc7c928Provider(loginViaEmailComponent: parent1(component) as! LoginViaEmailComponent, rootComponent: parent2(component) as! RootComponent)
}
private class DetermineAuthMethodComponentDependency527e70b5dbcfcb8f2023Provider: DetermineAuthMethodComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    var environmentType: BackendEnvironmentType {
        return rootComponent.environmentType
    }
    var backendConfig: BackendConfig {
        return rootComponent.backendConfig
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
    var existsAnotherAccount: Bool {
        return rootComponent.existsAnotherAccount
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
private class SwitchBackendConfirmationComponentDependency7a1956d88810c08ef169Provider: SwitchBackendConfirmationComponentDependency {
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
/// ^->RootComponent->DetermineAuthMethodComponent->SwitchBackendConfirmationComponent
private func factorye1144df20d596f07c3bea9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SwitchBackendConfirmationComponentDependency7a1956d88810c08ef169Provider(rootComponent: parent2(component) as! RootComponent)
}
private class LoginViaSSODependencycb22423a897409b8b5faProvider: LoginViaSSODependency {


    init() {

    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaSSOComponent
private func factory075263b25e612b6948d3e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaSSODependencycb22423a897409b8b5faProvider()
}
private class NoHistoryComponentDependencya1005f718577ea03ea08Provider: NoHistoryComponentDependency {
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
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent
private func factory5f94de319ad3e04a942321a9c45ed079aafca21f(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(rootComponent: parent4(component) as! RootComponent)
}
/// ^->RootComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent
private func factory5f94de319ad3e04a942342f5655bf2362a8495f6(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(rootComponent: parent3(component) as! RootComponent)
}
/// ^->RootComponent->DetermineAuthMethodComponent->NoHistoryComponent
private func factory5f94de319ad3e04a9423a9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(rootComponent: parent2(component) as! RootComponent)
}
/// ^->RootComponent->NoHistoryComponent
private func factory5f94de319ad3e04a9423b3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(rootComponent: parent1(component) as! RootComponent)
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
    var existsAnotherAccount: Bool {
        return rootComponent.existsAnotherAccount
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
private class LoginViaEmailComponentDependency6f812ea9ca4f0322dd27Provider: LoginViaEmailComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    var preferredAPIVersion: APIVersion? {
        return rootComponent.preferredAPIVersion
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
    var appStoreURL: URL {
        return rootComponent.appStoreURL
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent
private func factory9bda312c16141c932061a9403e3301bb54f80df0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaEmailComponentDependency6f812ea9ca4f0322dd27Provider(rootComponent: parent2(component) as! RootComponent)
}
/// ^->RootComponent->LoginViaEmailComponent
private func factory9bda312c16141c932061b3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoginViaEmailComponentDependency6f812ea9ca4f0322dd27Provider(rootComponent: parent1(component) as! RootComponent)
}

#else
extension VerificationCodeComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerificationCodeComponentDependency.router] = "router-any Router"
        keyPathToName[\VerificationCodeComponentDependency.loginViaEmailUseCase] = "loginViaEmailUseCase-any LoginViaEmailUseCaseProtocol"
        keyPathToName[\VerificationCodeComponentDependency.authenticationAPI] = "authenticationAPI-any AuthenticationAPI"
        keyPathToName[\VerificationCodeComponentDependency.backendEnvironment] = "backendEnvironment-WireAuthenticationBackendEnvironment"
        keyPathToName[\VerificationCodeComponentDependency.networkStack] = "networkStack-NetworkStack"
        keyPathToName[\VerificationCodeComponentDependency.didDetectDomainConflict] = "didDetectDomainConflict-Bool"

    }
}
extension DetermineAuthMethodComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\DetermineAuthMethodComponentDependency.router] = "router-any Router"
        keyPathToName[\DetermineAuthMethodComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\DetermineAuthMethodComponentDependency.environmentType] = "environmentType-BackendEnvironmentType"
        keyPathToName[\DetermineAuthMethodComponentDependency.backendConfig] = "backendConfig-BackendConfig"
        keyPathToName[\DetermineAuthMethodComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\DetermineAuthMethodComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\DetermineAuthMethodComponentDependency.ssoCallbackURLScheme] = "ssoCallbackURLScheme-String"
        keyPathToName[\DetermineAuthMethodComponentDependency.userDefaults] = "userDefaults-UserDefaults"
        keyPathToName[\DetermineAuthMethodComponentDependency.appStoreURL] = "appStoreURL-URL"
        keyPathToName[\DetermineAuthMethodComponentDependency.existsAnotherAccount] = "existsAnotherAccount-Bool"
        localTable["networkStack-NetworkStack"] = { [unowned self] in self.networkStack as Any }
        localTable["networkService-NetworkService"] = { [unowned self] in self.networkService as Any }
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

    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["environmentType-BackendEnvironmentType"] = { [unowned self] in self.environmentType as Any }
        localTable["backendConfig-BackendConfig"] = { [unowned self] in self.backendConfig as Any }
        localTable["preferredAPIVersion-APIVersion?"] = { [unowned self] in self.preferredAPIVersion as Any }
        localTable["productionVersions-Set<APIVersion>"] = { [unowned self] in self.productionVersions as Any }
        localTable["minTLSVersion-TLSVersion"] = { [unowned self] in self.minTLSVersion as Any }
        localTable["howToChangeEmailURL-URL"] = { [unowned self] in self.howToChangeEmailURL as Any }
        localTable["howToDeleteAccountURL-URL"] = { [unowned self] in self.howToDeleteAccountURL as Any }
        localTable["passwordValidator-any PasswordValidator"] = { [unowned self] in self.passwordValidator as Any }
        localTable["ssoCallbackURLScheme-String"] = { [unowned self] in self.ssoCallbackURLScheme as Any }
        localTable["userDefaults-UserDefaults"] = { [unowned self] in self.userDefaults as Any }
        localTable["appStoreURL-URL"] = { [unowned self] in self.appStoreURL as Any }
        localTable["existsAnotherAccount-Bool"] = { [unowned self] in self.existsAnotherAccount as Any }
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
        keyPathToName[\DetermineAuthMethodOnPremComponentDependency.existsAnotherAccount] = "existsAnotherAccount-Bool"
        localTable["networkService-NetworkService"] = { [unowned self] in self.networkService as Any }
    }
}
extension LoginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailComponentDependency.router] = "router-any Router"
        keyPathToName[\LoginViaEmailComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\LoginViaEmailComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\LoginViaEmailComponentDependency.environmentType] = "environmentType-BackendEnvironmentType"
        keyPathToName[\LoginViaEmailComponentDependency.backendConfig] = "backendConfig-BackendConfig"
        keyPathToName[\LoginViaEmailComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\LoginViaEmailComponentDependency.appStoreURL] = "appStoreURL-URL"
        localTable["email-String?"] = { [unowned self] in self.email as Any }
        localTable["didDetectDomainConflict-Bool"] = { [unowned self] in self.didDetectDomainConflict as Any }
        localTable["networkStack-NetworkStack"] = { [unowned self] in self.networkStack as Any }
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
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent", factoryd3638676a47fce1fe62317031e1ba787d83cb463)
    registerProviderFactory("^->RootComponent->LoginViaEmailComponent->VerificationCodeComponent", factoryd3638676a47fce1fe623a054ff50c10da855de8a)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent->VerificationCodeComponent", factoryd3638676a47fce1fe62317031e1ba787d83cb463)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent", factoryd47fa74281e135cd9f10b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->SwitchBackendConfirmationComponent", factorye1144df20d596f07c3bea9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->SwitchBackendConfirmationComponent", factorye1144df20d596f07c3bea9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaSSOComponent", factory075263b25e612b6948d3e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->SwitchBackendConfirmationComponent->LoginViaSSOComponent", factory075263b25e612b6948d3e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->SwitchBackendConfirmationComponent->LoginViaSSOComponent", factory075263b25e612b6948d3e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaSSOComponent", factory075263b25e612b6948d3e3b0c44298fc1c149afb)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent", factory5f94de319ad3e04a942321a9c45ed079aafca21f)
    registerProviderFactory("^->RootComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent", factory5f94de319ad3e04a942342f5655bf2362a8495f6)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent", factory5f94de319ad3e04a942321a9c45ed079aafca21f)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->NoHistoryComponent", factory5f94de319ad3e04a9423a9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->NoHistoryComponent", factory5f94de319ad3e04a9423b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->NoHistoryComponent", factory5f94de319ad3e04a9423a9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent", factorydbdff85f3341dce5e925b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent", factory9bda312c16141c932061a9403e3301bb54f80df0)
    registerProviderFactory("^->RootComponent->LoginViaEmailComponent", factory9bda312c16141c932061b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodOnPremComponent->LoginViaEmailComponent", factory9bda312c16141c932061a9403e3301bb54f80df0)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
