

import Combine
import Foundation
import NeedleFoundation
import SwiftUI
import WireAuthenticationAPI
import WireFoundation
import WireLegacyLogging
import WireMultiBackendUI
import WireNetwork
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

private class VerificationEmailCodeComponentDependency1187b119f31c839e0ba3Provider: VerificationEmailCodeComponentDependency {
    var networkStack: NetworkStack {
        return loginViaEmailComponent.networkStack
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    var router: any Router {
        return rootComponent.router
    }
    var registrationAnalyticsTracker: (any RegistrationAnalyticsTrackerProtocol)? {
        return rootComponent.registrationAnalyticsTracker
    }
    private let loginViaEmailComponent: LoginViaEmailComponent
    private let rootComponent: RootComponent
    init(loginViaEmailComponent: LoginViaEmailComponent, rootComponent: RootComponent) {
        self.loginViaEmailComponent = loginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->PersonalAccountCreationComponent->VerificationEmailCodeComponent
private func factoryd09536bf5bccb74b4ca640b4d17f468382eeae3b(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationEmailCodeComponentDependency1187b119f31c839e0ba3Provider(loginViaEmailComponent: parent2(component) as! LoginViaEmailComponent, rootComponent: parent4(component) as! RootComponent)
}
private class VerificationCodeComponentDependency90fbac803a630b372c4dProvider: VerificationCodeComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var networkStack: NetworkStack {
        return reloginViaEmailComponent.networkStack
    }
    var didDetectDomainConflict: Bool {
        return reloginViaEmailComponent.didDetectDomainConflict
    }
    private let reloginViaEmailComponent: ReloginViaEmailComponent
    private let rootComponent: RootComponent
    init(reloginViaEmailComponent: ReloginViaEmailComponent, rootComponent: RootComponent) {
        self.reloginViaEmailComponent = reloginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->ReloginViaEmailComponent->VerificationCodeComponent
private func factoryca1bd85b931d32e1f1f63e5bc7275f3d892b3f56(_ component: NeedleFoundation.Scope) -> AnyObject {
    return VerificationCodeComponentDependency90fbac803a630b372c4dProvider(reloginViaEmailComponent: parent1(component) as! ReloginViaEmailComponent, rootComponent: parent2(component) as! RootComponent)
}
private class VerificationCodeComponentDependency48f3b80358781bc7c928Provider: VerificationCodeComponentDependency {
    var router: any Router {
        return rootComponent.router
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
private class ReloginViaSSOComponentDependency1fa713d341e1cd065fabProvider: ReloginViaSSOComponentDependency {
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
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->ReloginViaSSOComponent
private func factory98c97a7d16256e5f522fb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ReloginViaSSOComponentDependency1fa713d341e1cd065fabProvider(rootComponent: parent1(component) as! RootComponent)
}
private class DetermineAuthMethodComponentDependency527e70b5dbcfcb8f2023Provider: DetermineAuthMethodComponentDependency {
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
    var isMultibackendEnabled: Bool {
        return rootComponent.isMultibackendEnabled
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
private class PersonalAccountCreationComponentDependency9e5e5a00f5c85fcf54b5Provider: PersonalAccountCreationComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var networkStack: NetworkStack {
        return loginViaEmailComponent.networkStack
    }
    var passwordValidator: any PasswordValidator {
        return rootComponent.passwordValidator
    }
    var privacyPolicyURL: URL {
        return rootComponent.privacyPolicyURL
    }
    var termsOfUseURL: URL {
        return rootComponent.termsOfUseURL
    }
    var registrationAnalyticsTracker: (any RegistrationAnalyticsTrackerProtocol)? {
        return rootComponent.registrationAnalyticsTracker
    }
    private let loginViaEmailComponent: LoginViaEmailComponent
    private let rootComponent: RootComponent
    init(loginViaEmailComponent: LoginViaEmailComponent, rootComponent: RootComponent) {
        self.loginViaEmailComponent = loginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->PersonalAccountCreationComponent
private func factory98c59649331d50383edd17031e1ba787d83cb463(_ component: NeedleFoundation.Scope) -> AnyObject {
    return PersonalAccountCreationComponentDependency9e5e5a00f5c85fcf54b5Provider(loginViaEmailComponent: parent1(component) as! LoginViaEmailComponent, rootComponent: parent3(component) as! RootComponent)
}
private class ReloginViaEmailComponentDependencye0e4f0af4d91e372688eProvider: ReloginViaEmailComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    var environment: BackendEnvironment2 {
        return rootComponent.environment
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->ReloginViaEmailComponent
private func factory8543c2220af4e432a73bb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ReloginViaEmailComponentDependencye0e4f0af4d91e372688eProvider(rootComponent: parent1(component) as! RootComponent)
}
private class AccountSwitcherComponentDependency65306f6262d465ec7963Provider: AccountSwitcherComponentDependency {
    var router: any Router {
        return rootComponent.router
    }
    var accountsPublisher: CurrentValuePublisher<[AccountUIModel]> {
        return rootComponent.accountsPublisher
    }
    var environment: BackendEnvironment2 {
        return rootComponent.environment
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->AccountSwitcherComponent
private func factory74ea254f881cfa30d8aeb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return AccountSwitcherComponentDependency65306f6262d465ec7963Provider(rootComponent: parent1(component) as! RootComponent)
}
private class NoHistoryComponentDependencyb786d25983e41ae1a973Provider: NoHistoryComponentDependency {
    var didReauthenticate: Bool {
        return reloginViaEmailComponent.didReauthenticate
    }
    var howToChangeEmailURL: URL {
        return rootComponent.howToChangeEmailURL
    }
    var howToDeleteAccountURL: URL {
        return rootComponent.howToDeleteAccountURL
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    private let reloginViaEmailComponent: ReloginViaEmailComponent
    private let rootComponent: RootComponent
    init(reloginViaEmailComponent: ReloginViaEmailComponent, rootComponent: RootComponent) {
        self.reloginViaEmailComponent = reloginViaEmailComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->ReloginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent
private func factorya89a4957e5aff796511adfcc12e333ee27bcee04(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencyb786d25983e41ae1a973Provider(reloginViaEmailComponent: parent2(component) as! ReloginViaEmailComponent, rootComponent: parent3(component) as! RootComponent)
}
/// ^->RootComponent->ReloginViaEmailComponent->NoHistoryComponent
private func factorya89a4957e5aff796511a3e5bc7275f3d892b3f56(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencyb786d25983e41ae1a973Provider(reloginViaEmailComponent: parent1(component) as! ReloginViaEmailComponent, rootComponent: parent2(component) as! RootComponent)
}
private class NoHistoryComponentDependencya1005f718577ea03ea08Provider: NoHistoryComponentDependency {
    var didReauthenticate: Bool {
        return determineAuthMethodComponent.didReauthenticate
    }
    var howToChangeEmailURL: URL {
        return rootComponent.howToChangeEmailURL
    }
    var howToDeleteAccountURL: URL {
        return rootComponent.howToDeleteAccountURL
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
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent
private func factory5f94de319ad3e04a9423f4a04d5110b9125fa4a4(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(determineAuthMethodComponent: parent3(component) as! DetermineAuthMethodComponent, rootComponent: parent4(component) as! RootComponent)
}
/// ^->RootComponent->DetermineAuthMethodComponent->NoHistoryComponent
private func factory5f94de319ad3e04a9423c770221f242f9204cf85(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(determineAuthMethodComponent: parent1(component) as! DetermineAuthMethodComponent, rootComponent: parent2(component) as! RootComponent)
}
/// ^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->NoHistoryComponent
private func factory5f94de319ad3e04a94230d0d1062090c141f4368(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependencya1005f718577ea03ea08Provider(determineAuthMethodComponent: parent2(component) as! DetermineAuthMethodComponent, rootComponent: parent3(component) as! RootComponent)
}
private class NoHistoryComponentDependency0ccc6e9877b3e68b8dcfProvider: NoHistoryComponentDependency {
    var didReauthenticate: Bool {
        return reloginViaSSOComponent.didReauthenticate
    }
    var howToChangeEmailURL: URL {
        return rootComponent.howToChangeEmailURL
    }
    var howToDeleteAccountURL: URL {
        return rootComponent.howToDeleteAccountURL
    }
    var bridge: WireAuthenticationBridge {
        return rootComponent.bridge
    }
    private let reloginViaSSOComponent: ReloginViaSSOComponent
    private let rootComponent: RootComponent
    init(reloginViaSSOComponent: ReloginViaSSOComponent, rootComponent: RootComponent) {
        self.reloginViaSSOComponent = reloginViaSSOComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->ReloginViaSSOComponent->NoHistoryComponent
private func factory98b867c04adda3043350ec0cf2b5c604e8c6aa9b(_ component: NeedleFoundation.Scope) -> AnyObject {
    return NoHistoryComponentDependency0ccc6e9877b3e68b8dcfProvider(reloginViaSSOComponent: parent1(component) as! ReloginViaSSOComponent, rootComponent: parent2(component) as! RootComponent)
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
    var environment: BackendEnvironment2 {
        return rootComponent.environment
    }
    var minTLSVersion: TLSVersion {
        return rootComponent.minTLSVersion
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

#else
extension VerificationEmailCodeComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerificationEmailCodeComponentDependency.networkStack] = "networkStack-NetworkStack"
        keyPathToName[\VerificationEmailCodeComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\VerificationEmailCodeComponentDependency.router] = "router-any Router"
        keyPathToName[\VerificationEmailCodeComponentDependency.registrationAnalyticsTracker] = "registrationAnalyticsTracker-(any RegistrationAnalyticsTrackerProtocol)?"
    }
}
extension VerificationCodeComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\VerificationCodeComponentDependency.router] = "router-any Router"
        keyPathToName[\VerificationCodeComponentDependency.networkStack] = "networkStack-NetworkStack"
        keyPathToName[\VerificationCodeComponentDependency.didDetectDomainConflict] = "didDetectDomainConflict-Bool"

    }
}
extension ReloginViaSSOComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\ReloginViaSSOComponentDependency.router] = "router-any Router"
        keyPathToName[\ReloginViaSSOComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\ReloginViaSSOComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\ReloginViaSSOComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\ReloginViaSSOComponentDependency.ssoCallbackURLScheme] = "ssoCallbackURLScheme-String"
        localTable["didReauthenticate-Bool"] = { [unowned self] in self.didReauthenticate as Any }
    }
}
extension DetermineAuthMethodComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\DetermineAuthMethodComponentDependency.router] = "router-any Router"
        keyPathToName[\DetermineAuthMethodComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\DetermineAuthMethodComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\DetermineAuthMethodComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        keyPathToName[\DetermineAuthMethodComponentDependency.ssoCallbackURLScheme] = "ssoCallbackURLScheme-String"
        keyPathToName[\DetermineAuthMethodComponentDependency.isMultibackendEnabled] = "isMultibackendEnabled-Bool"
        localTable["networkStack-NetworkStack"] = { [unowned self] in self.networkStack as Any }
        localTable["didReauthenticate-Bool"] = { [unowned self] in self.didReauthenticate as Any }
    }
}
extension PersonalAccountCreationComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\PersonalAccountCreationComponentDependency.router] = "router-any Router"
        keyPathToName[\PersonalAccountCreationComponentDependency.networkStack] = "networkStack-NetworkStack"
        keyPathToName[\PersonalAccountCreationComponentDependency.passwordValidator] = "passwordValidator-any PasswordValidator"
        keyPathToName[\PersonalAccountCreationComponentDependency.privacyPolicyURL] = "privacyPolicyURL-URL"
        keyPathToName[\PersonalAccountCreationComponentDependency.termsOfUseURL] = "termsOfUseURL-URL"
        keyPathToName[\PersonalAccountCreationComponentDependency.registrationAnalyticsTracker] = "registrationAnalyticsTracker-(any RegistrationAnalyticsTrackerProtocol)?"

    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["environment-BackendEnvironment2"] = { [unowned self] in self.environment as Any }
        localTable["preferredAPIVersion-APIVersion?"] = { [unowned self] in self.preferredAPIVersion as Any }
        localTable["productionVersions-Set<APIVersion>"] = { [unowned self] in self.productionVersions as Any }
        localTable["minTLSVersion-TLSVersion"] = { [unowned self] in self.minTLSVersion as Any }
        localTable["howToChangeEmailURL-URL"] = { [unowned self] in self.howToChangeEmailURL as Any }
        localTable["howToDeleteAccountURL-URL"] = { [unowned self] in self.howToDeleteAccountURL as Any }
        localTable["privacyPolicyURL-URL"] = { [unowned self] in self.privacyPolicyURL as Any }
        localTable["termsOfUseURL-URL"] = { [unowned self] in self.termsOfUseURL as Any }
        localTable["passwordValidator-any PasswordValidator"] = { [unowned self] in self.passwordValidator as Any }
        localTable["ssoCallbackURLScheme-String"] = { [unowned self] in self.ssoCallbackURLScheme as Any }
        localTable["appStoreURL-URL"] = { [unowned self] in self.appStoreURL as Any }
        localTable["accountsPublisher-CurrentValuePublisher<[AccountUIModel]>"] = { [unowned self] in self.accountsPublisher as Any }
        localTable["isMultibackendEnabled-Bool"] = { [unowned self] in self.isMultibackendEnabled as Any }
        localTable["registrationAnalyticsTracker-(any RegistrationAnalyticsTrackerProtocol)?"] = { [unowned self] in self.registrationAnalyticsTracker as Any }
        localTable["bridge-WireAuthenticationBridge"] = { [unowned self] in self.bridge as Any }
        localTable["router-any Router"] = { [unowned self] in self.router as Any }
    }
}
extension ReloginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\ReloginViaEmailComponentDependency.router] = "router-any Router"
        keyPathToName[\ReloginViaEmailComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\ReloginViaEmailComponentDependency.environment] = "environment-BackendEnvironment2"
        localTable["email-String"] = { [unowned self] in self.email as Any }
        localTable["networkStack-NetworkStack"] = { [unowned self] in self.networkStack as Any }
        localTable["didReauthenticate-Bool"] = { [unowned self] in self.didReauthenticate as Any }
        localTable["didDetectDomainConflict-Bool"] = { [unowned self] in self.didDetectDomainConflict as Any }
    }
}
extension AccountSwitcherComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\AccountSwitcherComponentDependency.router] = "router-any Router"
        keyPathToName[\AccountSwitcherComponentDependency.accountsPublisher] = "accountsPublisher-CurrentValuePublisher<[AccountUIModel]>"
        keyPathToName[\AccountSwitcherComponentDependency.environment] = "environment-BackendEnvironment2"
    }
}
extension NoHistoryComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\NoHistoryComponentDependency.didReauthenticate] = "didReauthenticate-Bool"
        keyPathToName[\NoHistoryComponentDependency.howToChangeEmailURL] = "howToChangeEmailURL-URL"
        keyPathToName[\NoHistoryComponentDependency.howToDeleteAccountURL] = "howToDeleteAccountURL-URL"
        keyPathToName[\NoHistoryComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
    }
}
extension LoginViaEmailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\LoginViaEmailComponentDependency.router] = "router-any Router"
        keyPathToName[\LoginViaEmailComponentDependency.bridge] = "bridge-WireAuthenticationBridge"
        keyPathToName[\LoginViaEmailComponentDependency.preferredAPIVersion] = "preferredAPIVersion-APIVersion?"
        keyPathToName[\LoginViaEmailComponentDependency.environment] = "environment-BackendEnvironment2"
        keyPathToName[\LoginViaEmailComponentDependency.minTLSVersion] = "minTLSVersion-TLSVersion"
        localTable["email-String?"] = { [unowned self] in self.email as Any }
        localTable["didDetectDomainConflict-Bool"] = { [unowned self] in self.didDetectDomainConflict as Any }
        localTable["networkStack-NetworkStack"] = { [unowned self] in self.networkStack as Any }
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
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->PersonalAccountCreationComponent->VerificationEmailCodeComponent", factoryd09536bf5bccb74b4ca640b4d17f468382eeae3b)
    registerProviderFactory("^->RootComponent->ReloginViaEmailComponent->VerificationCodeComponent", factoryca1bd85b931d32e1f1f63e5bc7275f3d892b3f56)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent", factoryd3638676a47fce1fe62317031e1ba787d83cb463)
    registerProviderFactory("^->RootComponent->ReloginViaSSOComponent", factory98c97a7d16256e5f522fb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent", factoryd47fa74281e135cd9f10b3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->PersonalAccountCreationComponent", factory98c59649331d50383edd17031e1ba787d83cb463)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->ReloginViaEmailComponent", factory8543c2220af4e432a73bb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->AccountSwitcherComponent", factory74ea254f881cfa30d8aeb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->ReloginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent", factorya89a4957e5aff796511adfcc12e333ee27bcee04)
    registerProviderFactory("^->RootComponent->ReloginViaEmailComponent->NoHistoryComponent", factorya89a4957e5aff796511a3e5bc7275f3d892b3f56)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->VerificationCodeComponent->NoHistoryComponent", factory5f94de319ad3e04a9423f4a04d5110b9125fa4a4)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->NoHistoryComponent", factory5f94de319ad3e04a9423c770221f242f9204cf85)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent->NoHistoryComponent", factory5f94de319ad3e04a94230d0d1062090c141f4368)
    registerProviderFactory("^->RootComponent->ReloginViaSSOComponent->NoHistoryComponent", factory98b867c04adda3043350ec0cf2b5c604e8c6aa9b)
    registerProviderFactory("^->RootComponent->DetermineAuthMethodComponent->LoginViaEmailComponent", factory9bda312c16141c932061a9403e3301bb54f80df0)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
