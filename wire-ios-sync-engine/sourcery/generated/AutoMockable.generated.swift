// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import WireSyncEngine





















public class MockCertificateRevocationListsChecking: CertificateRevocationListsChecking {

    // MARK: - Life cycle

    public init() {}


    // MARK: - checkNewCRLs

    public var checkNewCRLsFrom_Invocations: [CRLsDistributionPoints] = []
    public var checkNewCRLsFrom_MockMethod: ((CRLsDistributionPoints) async -> Void)?

    public func checkNewCRLs(from distributionPoints: CRLsDistributionPoints) async {
        checkNewCRLsFrom_Invocations.append(distributionPoints)

        guard let mock = checkNewCRLsFrom_MockMethod else {
            fatalError("no mock for `checkNewCRLsFrom`")
        }

        await mock(distributionPoints)
    }

    // MARK: - checkExpiredCRLs

    public var checkExpiredCRLs_Invocations: [Void] = []
    public var checkExpiredCRLs_MockMethod: (() async -> Void)?

    public func checkExpiredCRLs() async {
        checkExpiredCRLs_Invocations.append(())

        guard let mock = checkExpiredCRLs_MockMethod else {
            fatalError("no mock for `checkExpiredCRLs`")
        }

        await mock()
    }

}

public class MockE2EIdentityCertificateUpdateStatusUseCaseProtocol: E2EIdentityCertificateUpdateStatusUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> E2EIdentityCertificateUpdateStatus)?
    public var invoke_MockValue: E2EIdentityCertificateUpdateStatus?

    public func invoke() async throws -> E2EIdentityCertificateUpdateStatus {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        if let mock = invoke_MockMethod {
            return try await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockGetE2eIdentityCertificatesUseCaseProtocol: GetE2eIdentityCertificatesUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeMlsGroupIdClientIds_Invocations: [(mlsGroupId: MLSGroupID, clientIds: [MLSClientID])] = []
    public var invokeMlsGroupIdClientIds_MockError: Error?
    public var invokeMlsGroupIdClientIds_MockMethod: ((MLSGroupID, [MLSClientID]) async throws -> [E2eIdentityCertificate])?
    public var invokeMlsGroupIdClientIds_MockValue: [E2eIdentityCertificate]?

    public func invoke(mlsGroupId: MLSGroupID, clientIds: [MLSClientID]) async throws -> [E2eIdentityCertificate] {
        invokeMlsGroupIdClientIds_Invocations.append((mlsGroupId: mlsGroupId, clientIds: clientIds))

        if let error = invokeMlsGroupIdClientIds_MockError {
            throw error
        }

        if let mock = invokeMlsGroupIdClientIds_MockMethod {
            return try await mock(mlsGroupId, clientIds)
        } else if let mock = invokeMlsGroupIdClientIds_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeMlsGroupIdClientIds`")
        }
    }

}

public class MockGetIsE2EIdentityEnabledUseCaseProtocol: GetIsE2EIdentityEnabledUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> Bool)?
    public var invoke_MockValue: Bool?

    public func invoke() async throws -> Bool {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        if let mock = invoke_MockMethod {
            return try await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockGetMLSFeatureUseCaseProtocol: GetMLSFeatureUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockMethod: (() -> Feature.MLS)?
    public var invoke_MockValue: Feature.MLS?

    public func invoke() -> Feature.MLS {
        invoke_Invocations.append(())

        if let mock = invoke_MockMethod {
            return mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockGetUserClientFingerprintUseCaseProtocol: GetUserClientFingerprintUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeUserClient_Invocations: [UserClient] = []
    public var invokeUserClient_MockMethod: ((UserClient) async -> Data?)?
    public var invokeUserClient_MockValue: Data??

    public func invoke(userClient: UserClient) async -> Data? {
        invokeUserClient_Invocations.append(userClient)

        if let mock = invokeUserClient_MockMethod {
            return await mock(userClient)
        } else if let mock = invokeUserClient_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUserClient`")
        }
    }

}

public class MockIsE2EICertificateEnrollmentRequiredProtocol: IsE2EICertificateEnrollmentRequiredProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> Bool)?
    public var invoke_MockValue: Bool?

    public func invoke() async throws -> Bool {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        if let mock = invoke_MockMethod {
            return try await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockPasteboard: Pasteboard {

    // MARK: - Life cycle

    public init() {}

    // MARK: - text

    public var text: String?


}

class MockRecurringActionServiceInterface: RecurringActionServiceInterface {

    // MARK: - Life cycle



    // MARK: - performActionsIfNeeded

    var performActionsIfNeeded_Invocations: [Void] = []
    var performActionsIfNeeded_MockMethod: (() -> Void)?

    func performActionsIfNeeded() {
        performActionsIfNeeded_Invocations.append(())

        guard let mock = performActionsIfNeeded_MockMethod else {
            fatalError("no mock for `performActionsIfNeeded`")
        }

        mock()
    }

    // MARK: - registerAction

    var registerAction_Invocations: [RecurringAction] = []
    var registerAction_MockMethod: ((RecurringAction) -> Void)?

    func registerAction(_ action: RecurringAction) {
        registerAction_Invocations.append(action)

        guard let mock = registerAction_MockMethod else {
            fatalError("no mock for `registerAction`")
        }

        mock(action)
    }

    // MARK: - forcePerformAction

    var forcePerformActionId_Invocations: [String] = []
    var forcePerformActionId_MockMethod: ((String) -> Void)?

    func forcePerformAction(id: String) {
        forcePerformActionId_Invocations.append(id)

        guard let mock = forcePerformActionId_MockMethod else {
            fatalError("no mock for `forcePerformActionId`")
        }

        mock(id)
    }

    // MARK: - removeAction

    var removeActionId_Invocations: [String] = []
    var removeActionId_MockMethod: ((String) -> Void)?

    func removeAction(id: String) {
        removeActionId_Invocations.append(id)

        guard let mock = removeActionId_MockMethod else {
            fatalError("no mock for `removeActionId`")
        }

        mock(id)
    }

}

public class MockResolveOneOnOneConversationsUseCaseProtocol: ResolveOneOnOneConversationsUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> Void)?

    public func invoke() async throws {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        guard let mock = invoke_MockMethod else {
            fatalError("no mock for `invoke`")
        }

        try await mock()
    }

}

public class MockSelfClientCertificateProviderProtocol: SelfClientCertificateProviderProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - hasCertificate

    public var hasCertificateCallsCount = 0
    public var hasCertificateCalled: Bool {
        return hasCertificateCallsCount > 0
    }

    public var hasCertificate: Bool {
        get async {
            hasCertificateCallsCount += 1
            if let hasCertificateClosure = hasCertificateClosure {
                return await hasCertificateClosure()
            } else {
                return underlyingHasCertificate
            }
        }
    }
    public var underlyingHasCertificate: Bool!
    public var hasCertificateClosure: (() async -> Bool)?


    // MARK: - getCertificate

    public var getCertificate_Invocations: [Void] = []
    public var getCertificate_MockError: Error?
    public var getCertificate_MockMethod: (() async throws -> E2eIdentityCertificate?)?
    public var getCertificate_MockValue: E2eIdentityCertificate??

    public func getCertificate() async throws -> E2eIdentityCertificate? {
        getCertificate_Invocations.append(())

        if let error = getCertificate_MockError {
            throw error
        }

        if let mock = getCertificate_MockMethod {
            return try await mock()
        } else if let mock = getCertificate_MockValue {
            return mock
        } else {
            fatalError("no mock for `getCertificate`")
        }
    }

}

public class MockServerConnection: ServerConnection {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isMobileConnection

    public var isMobileConnection: Bool {
        get { return underlyingIsMobileConnection }
        set(value) { underlyingIsMobileConnection = value }
    }

    public var underlyingIsMobileConnection: Bool!

    // MARK: - isOffline

    public var isOffline: Bool {
        get { return underlyingIsOffline }
        set(value) { underlyingIsOffline = value }
    }

    public var underlyingIsOffline: Bool!


}

public class MockSessionManagerDelegate: SessionManagerDelegate {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isInAuthenticatedAppState

    public var isInAuthenticatedAppState: Bool {
        get { return underlyingIsInAuthenticatedAppState }
        set(value) { underlyingIsInAuthenticatedAppState = value }
    }

    public var underlyingIsInAuthenticatedAppState: Bool!

    // MARK: - isInUnathenticatedAppState

    public var isInUnathenticatedAppState: Bool {
        get { return underlyingIsInUnathenticatedAppState }
        set(value) { underlyingIsInUnathenticatedAppState = value }
    }

    public var underlyingIsInUnathenticatedAppState: Bool!


    // MARK: - sessionManagerDidFailToLogin

    public var sessionManagerDidFailToLoginError_Invocations: [Error?] = []
    public var sessionManagerDidFailToLoginError_MockMethod: ((Error?) -> Void)?

    public func sessionManagerDidFailToLogin(error: Error?) {
        sessionManagerDidFailToLoginError_Invocations.append(error)

        guard let mock = sessionManagerDidFailToLoginError_MockMethod else {
            fatalError("no mock for `sessionManagerDidFailToLoginError`")
        }

        mock(error)
    }

    // MARK: - sessionManagerWillLogout

    public var sessionManagerWillLogoutErrorUserSessionCanBeTornDown_Invocations: [(error: Error?, userSessionCanBeTornDown: (() -> Void)?)] = []
    public var sessionManagerWillLogoutErrorUserSessionCanBeTornDown_MockMethod: ((Error?, (() -> Void)?) -> Void)?

    public func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        sessionManagerWillLogoutErrorUserSessionCanBeTornDown_Invocations.append((error: error, userSessionCanBeTornDown: userSessionCanBeTornDown))

        guard let mock = sessionManagerWillLogoutErrorUserSessionCanBeTornDown_MockMethod else {
            fatalError("no mock for `sessionManagerWillLogoutErrorUserSessionCanBeTornDown`")
        }

        mock(error, userSessionCanBeTornDown)
    }

    // MARK: - sessionManagerWillOpenAccount

    public var sessionManagerWillOpenAccountFromUserSessionCanBeTornDown_Invocations: [(account: Account, selectedAccount: Account?, userSessionCanBeTornDown: () -> Void)] = []
    public var sessionManagerWillOpenAccountFromUserSessionCanBeTornDown_MockMethod: ((Account, Account?, @escaping () -> Void) -> Void)?

    public func sessionManagerWillOpenAccount(_ account: Account, from selectedAccount: Account?, userSessionCanBeTornDown: @escaping () -> Void) {
        sessionManagerWillOpenAccountFromUserSessionCanBeTornDown_Invocations.append((account: account, selectedAccount: selectedAccount, userSessionCanBeTornDown: userSessionCanBeTornDown))

        guard let mock = sessionManagerWillOpenAccountFromUserSessionCanBeTornDown_MockMethod else {
            fatalError("no mock for `sessionManagerWillOpenAccountFromUserSessionCanBeTornDown`")
        }

        mock(account, selectedAccount, userSessionCanBeTornDown)
    }

    // MARK: - sessionManagerWillMigrateAccount

    public var sessionManagerWillMigrateAccountUserSessionCanBeTornDown_Invocations: [() -> Void] = []
    public var sessionManagerWillMigrateAccountUserSessionCanBeTornDown_MockMethod: ((@escaping () -> Void) -> Void)?

    public func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        sessionManagerWillMigrateAccountUserSessionCanBeTornDown_Invocations.append(userSessionCanBeTornDown)

        guard let mock = sessionManagerWillMigrateAccountUserSessionCanBeTornDown_MockMethod else {
            fatalError("no mock for `sessionManagerWillMigrateAccountUserSessionCanBeTornDown`")
        }

        mock(userSessionCanBeTornDown)
    }

    // MARK: - sessionManagerDidFailToLoadDatabase

    public var sessionManagerDidFailToLoadDatabaseError_Invocations: [Error] = []
    public var sessionManagerDidFailToLoadDatabaseError_MockMethod: ((Error) -> Void)?

    public func sessionManagerDidFailToLoadDatabase(error: Error) {
        sessionManagerDidFailToLoadDatabaseError_Invocations.append(error)

        guard let mock = sessionManagerDidFailToLoadDatabaseError_MockMethod else {
            fatalError("no mock for `sessionManagerDidFailToLoadDatabaseError`")
        }

        mock(error)
    }

    // MARK: - sessionManagerDidBlacklistCurrentVersion

    public var sessionManagerDidBlacklistCurrentVersionReason_Invocations: [BlacklistReason] = []
    public var sessionManagerDidBlacklistCurrentVersionReason_MockMethod: ((BlacklistReason) -> Void)?

    public func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        sessionManagerDidBlacklistCurrentVersionReason_Invocations.append(reason)

        guard let mock = sessionManagerDidBlacklistCurrentVersionReason_MockMethod else {
            fatalError("no mock for `sessionManagerDidBlacklistCurrentVersionReason`")
        }

        mock(reason)
    }

    // MARK: - sessionManagerDidBlacklistJailbrokenDevice

    public var sessionManagerDidBlacklistJailbrokenDevice_Invocations: [Void] = []
    public var sessionManagerDidBlacklistJailbrokenDevice_MockMethod: (() -> Void)?

    public func sessionManagerDidBlacklistJailbrokenDevice() {
        sessionManagerDidBlacklistJailbrokenDevice_Invocations.append(())

        guard let mock = sessionManagerDidBlacklistJailbrokenDevice_MockMethod else {
            fatalError("no mock for `sessionManagerDidBlacklistJailbrokenDevice`")
        }

        mock()
    }

    // MARK: - sessionManagerRequireCertificateEnrollment

    public var sessionManagerRequireCertificateEnrollment_Invocations: [Void] = []
    public var sessionManagerRequireCertificateEnrollment_MockMethod: (() -> Void)?

    public func sessionManagerRequireCertificateEnrollment() {
        sessionManagerRequireCertificateEnrollment_Invocations.append(())

        guard let mock = sessionManagerRequireCertificateEnrollment_MockMethod else {
            fatalError("no mock for `sessionManagerRequireCertificateEnrollment`")
        }

        mock()
    }

    // MARK: - sessionManagerDidEnrollCertificate

    public var sessionManagerDidEnrollCertificateFor_Invocations: [UserSession?] = []
    public var sessionManagerDidEnrollCertificateFor_MockMethod: ((UserSession?) -> Void)?

    public func sessionManagerDidEnrollCertificate(for activeSession: UserSession?) {
        sessionManagerDidEnrollCertificateFor_Invocations.append(activeSession)

        guard let mock = sessionManagerDidEnrollCertificateFor_MockMethod else {
            fatalError("no mock for `sessionManagerDidEnrollCertificateFor`")
        }

        mock(activeSession)
    }

    // MARK: - sessionManagerDidPerformFederationMigration

    public var sessionManagerDidPerformFederationMigrationActiveSession_Invocations: [UserSession?] = []
    public var sessionManagerDidPerformFederationMigrationActiveSession_MockMethod: ((UserSession?) -> Void)?

    public func sessionManagerDidPerformFederationMigration(activeSession: UserSession?) {
        sessionManagerDidPerformFederationMigrationActiveSession_Invocations.append(activeSession)

        guard let mock = sessionManagerDidPerformFederationMigrationActiveSession_MockMethod else {
            fatalError("no mock for `sessionManagerDidPerformFederationMigrationActiveSession`")
        }

        mock(activeSession)
    }

    // MARK: - sessionManagerDidPerformAPIMigrations

    public var sessionManagerDidPerformAPIMigrationsActiveSession_Invocations: [UserSession?] = []
    public var sessionManagerDidPerformAPIMigrationsActiveSession_MockMethod: ((UserSession?) -> Void)?

    public func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?) {
        sessionManagerDidPerformAPIMigrationsActiveSession_Invocations.append(activeSession)

        guard let mock = sessionManagerDidPerformAPIMigrationsActiveSession_MockMethod else {
            fatalError("no mock for `sessionManagerDidPerformAPIMigrationsActiveSession`")
        }

        mock(activeSession)
    }

    // MARK: - sessionManagerAsksToRetryStart

    public var sessionManagerAsksToRetryStart_Invocations: [Void] = []
    public var sessionManagerAsksToRetryStart_MockMethod: (() -> Void)?

    public func sessionManagerAsksToRetryStart() {
        sessionManagerAsksToRetryStart_Invocations.append(())

        guard let mock = sessionManagerAsksToRetryStart_MockMethod else {
            fatalError("no mock for `sessionManagerAsksToRetryStart`")
        }

        mock()
    }

    // MARK: - sessionManagerDidCompleteInitialSync

    public var sessionManagerDidCompleteInitialSyncFor_Invocations: [UserSession?] = []
    public var sessionManagerDidCompleteInitialSyncFor_MockMethod: ((UserSession?) -> Void)?

    public func sessionManagerDidCompleteInitialSync(for activeSession: UserSession?) {
        sessionManagerDidCompleteInitialSyncFor_Invocations.append(activeSession)

        guard let mock = sessionManagerDidCompleteInitialSyncFor_MockMethod else {
            fatalError("no mock for `sessionManagerDidCompleteInitialSyncFor`")
        }

        mock(activeSession)
    }

    // MARK: - sessionManagerDidChangeActiveUserSession

    public var sessionManagerDidChangeActiveUserSessionUserSession_Invocations: [ZMUserSession] = []
    public var sessionManagerDidChangeActiveUserSessionUserSession_MockMethod: ((ZMUserSession) -> Void)?

    public func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        sessionManagerDidChangeActiveUserSessionUserSession_Invocations.append(userSession)

        guard let mock = sessionManagerDidChangeActiveUserSessionUserSession_MockMethod else {
            fatalError("no mock for `sessionManagerDidChangeActiveUserSessionUserSession`")
        }

        mock(userSession)
    }

    // MARK: - sessionManagerDidReportLockChange

    public var sessionManagerDidReportLockChangeForSession_Invocations: [UserSession] = []
    public var sessionManagerDidReportLockChangeForSession_MockMethod: ((UserSession) -> Void)?

    public func sessionManagerDidReportLockChange(forSession session: UserSession) {
        sessionManagerDidReportLockChangeForSession_Invocations.append(session)

        guard let mock = sessionManagerDidReportLockChangeForSession_MockMethod else {
            fatalError("no mock for `sessionManagerDidReportLockChangeForSession`")
        }

        mock(session)
    }

}

public class MockSnoozeCertificateEnrollmentUseCaseProtocol: SnoozeCertificateEnrollmentUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeEndOfPeriodIsUpdateMode_Invocations: [(endOfPeriod: Date, isUpdateMode: Bool)] = []
    public var invokeEndOfPeriodIsUpdateMode_MockMethod: ((Date, Bool) async -> Void)?

    public func invoke(endOfPeriod: Date, isUpdateMode: Bool) async {
        invokeEndOfPeriodIsUpdateMode_Invocations.append((endOfPeriod: endOfPeriod, isUpdateMode: isUpdateMode))

        guard let mock = invokeEndOfPeriodIsUpdateMode_MockMethod else {
            fatalError("no mock for `invokeEndOfPeriodIsUpdateMode`")
        }

        await mock(endOfPeriod, isUpdateMode)
    }

}

public class MockStopCertificateEnrollmentSnoozerUseCaseProtocol: StopCertificateEnrollmentSnoozerUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockMethod: (() -> Void)?

    public func invoke() {
        invoke_Invocations.append(())

        guard let mock = invoke_MockMethod else {
            fatalError("no mock for `invoke`")
        }

        mock()
    }

}

public class MockUseCaseFactoryProtocol: UseCaseFactoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - createResolveOneOnOneUseCase

    public var createResolveOneOnOneUseCase_Invocations: [Void] = []
    public var createResolveOneOnOneUseCase_MockMethod: (() -> ResolveOneOnOneConversationsUseCaseProtocol)?
    public var createResolveOneOnOneUseCase_MockValue: ResolveOneOnOneConversationsUseCaseProtocol?

    public func createResolveOneOnOneUseCase() -> ResolveOneOnOneConversationsUseCaseProtocol {
        createResolveOneOnOneUseCase_Invocations.append(())

        if let mock = createResolveOneOnOneUseCase_MockMethod {
            return mock()
        } else if let mock = createResolveOneOnOneUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `createResolveOneOnOneUseCase`")
        }
    }

}

public class MockUserProfile: UserProfile {

    // MARK: - Life cycle

    public init() {}

    // MARK: - lastSuggestedHandle

    public var lastSuggestedHandle: String?


    // MARK: - requestPhoneVerificationCode

    public var requestPhoneVerificationCodePhoneNumber_Invocations: [String] = []
    public var requestPhoneVerificationCodePhoneNumber_MockMethod: ((String) -> Void)?

    public func requestPhoneVerificationCode(phoneNumber: String) {
        requestPhoneVerificationCodePhoneNumber_Invocations.append(phoneNumber)

        guard let mock = requestPhoneVerificationCodePhoneNumber_MockMethod else {
            fatalError("no mock for `requestPhoneVerificationCodePhoneNumber`")
        }

        mock(phoneNumber)
    }

    // MARK: - requestPhoneNumberChange

    public var requestPhoneNumberChangeCredentials_Invocations: [ZMPhoneCredentials] = []
    public var requestPhoneNumberChangeCredentials_MockMethod: ((ZMPhoneCredentials) -> Void)?

    public func requestPhoneNumberChange(credentials: ZMPhoneCredentials) {
        requestPhoneNumberChangeCredentials_Invocations.append(credentials)

        guard let mock = requestPhoneNumberChangeCredentials_MockMethod else {
            fatalError("no mock for `requestPhoneNumberChangeCredentials`")
        }

        mock(credentials)
    }

    // MARK: - requestPhoneNumberRemoval

    public var requestPhoneNumberRemoval_Invocations: [Void] = []
    public var requestPhoneNumberRemoval_MockMethod: (() -> Void)?

    public func requestPhoneNumberRemoval() {
        requestPhoneNumberRemoval_Invocations.append(())

        guard let mock = requestPhoneNumberRemoval_MockMethod else {
            fatalError("no mock for `requestPhoneNumberRemoval`")
        }

        mock()
    }

    // MARK: - requestEmailChange

    public var requestEmailChangeEmail_Invocations: [String] = []
    public var requestEmailChangeEmail_MockError: Error?
    public var requestEmailChangeEmail_MockMethod: ((String) throws -> Void)?

    public func requestEmailChange(email: String) throws {
        requestEmailChangeEmail_Invocations.append(email)

        if let error = requestEmailChangeEmail_MockError {
            throw error
        }

        guard let mock = requestEmailChangeEmail_MockMethod else {
            fatalError("no mock for `requestEmailChangeEmail`")
        }

        try mock(email)
    }

    // MARK: - requestSettingEmailAndPassword

    public var requestSettingEmailAndPasswordCredentials_Invocations: [ZMEmailCredentials] = []
    public var requestSettingEmailAndPasswordCredentials_MockError: Error?
    public var requestSettingEmailAndPasswordCredentials_MockMethod: ((ZMEmailCredentials) throws -> Void)?

    public func requestSettingEmailAndPassword(credentials: ZMEmailCredentials) throws {
        requestSettingEmailAndPasswordCredentials_Invocations.append(credentials)

        if let error = requestSettingEmailAndPasswordCredentials_MockError {
            throw error
        }

        guard let mock = requestSettingEmailAndPasswordCredentials_MockMethod else {
            fatalError("no mock for `requestSettingEmailAndPasswordCredentials`")
        }

        try mock(credentials)
    }

    // MARK: - cancelSettingEmailAndPassword

    public var cancelSettingEmailAndPassword_Invocations: [Void] = []
    public var cancelSettingEmailAndPassword_MockMethod: (() -> Void)?

    public func cancelSettingEmailAndPassword() {
        cancelSettingEmailAndPassword_Invocations.append(())

        guard let mock = cancelSettingEmailAndPassword_MockMethod else {
            fatalError("no mock for `cancelSettingEmailAndPassword`")
        }

        mock()
    }

    // MARK: - requestCheckHandleAvailability

    public var requestCheckHandleAvailabilityHandle_Invocations: [String] = []
    public var requestCheckHandleAvailabilityHandle_MockMethod: ((String) -> Void)?

    public func requestCheckHandleAvailability(handle: String) {
        requestCheckHandleAvailabilityHandle_Invocations.append(handle)

        guard let mock = requestCheckHandleAvailabilityHandle_MockMethod else {
            fatalError("no mock for `requestCheckHandleAvailabilityHandle`")
        }

        mock(handle)
    }

    // MARK: - requestSettingHandle

    public var requestSettingHandleHandle_Invocations: [String] = []
    public var requestSettingHandleHandle_MockMethod: ((String) -> Void)?

    public func requestSettingHandle(handle: String) {
        requestSettingHandleHandle_Invocations.append(handle)

        guard let mock = requestSettingHandleHandle_MockMethod else {
            fatalError("no mock for `requestSettingHandleHandle`")
        }

        mock(handle)
    }

    // MARK: - cancelSettingHandle

    public var cancelSettingHandle_Invocations: [Void] = []
    public var cancelSettingHandle_MockMethod: (() -> Void)?

    public func cancelSettingHandle() {
        cancelSettingHandle_Invocations.append(())

        guard let mock = cancelSettingHandle_MockMethod else {
            fatalError("no mock for `cancelSettingHandle`")
        }

        mock()
    }

    // MARK: - suggestHandles

    public var suggestHandles_Invocations: [Void] = []
    public var suggestHandles_MockMethod: (() -> Void)?

    public func suggestHandles() {
        suggestHandles_Invocations.append(())

        guard let mock = suggestHandles_MockMethod else {
            fatalError("no mock for `suggestHandles`")
        }

        mock()
    }

    // MARK: - add

    public var addObserver_Invocations: [UserProfileUpdateObserver] = []
    public var addObserver_MockMethod: ((UserProfileUpdateObserver) -> Any)?
    public var addObserver_MockValue: Any?

    @objc(addObserver:)
    public func add(observer: UserProfileUpdateObserver) -> Any {
        addObserver_Invocations.append(observer)

        if let mock = addObserver_MockMethod {
            return mock(observer)
        } else if let mock = addObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addObserver`")
        }
    }

}

public class MockUserSession: UserSession {

    // MARK: - Life cycle

    public init() {}

    // MARK: - lock

    public var lock: SessionLock?

    // MARK: - isLocked

    public var isLocked: Bool {
        get { return underlyingIsLocked }
        set(value) { underlyingIsLocked = value }
    }

    public var underlyingIsLocked: Bool!

    // MARK: - requiresScreenCurtain

    public var requiresScreenCurtain: Bool {
        get { return underlyingRequiresScreenCurtain }
        set(value) { underlyingRequiresScreenCurtain = value }
    }

    public var underlyingRequiresScreenCurtain: Bool!

    // MARK: - isAppLockActive

    public var isAppLockActive: Bool {
        get { return underlyingIsAppLockActive }
        set(value) { underlyingIsAppLockActive = value }
    }

    public var underlyingIsAppLockActive: Bool!

    // MARK: - isAppLockAvailable

    public var isAppLockAvailable: Bool {
        get { return underlyingIsAppLockAvailable }
        set(value) { underlyingIsAppLockAvailable = value }
    }

    public var underlyingIsAppLockAvailable: Bool!

    // MARK: - isAppLockForced

    public var isAppLockForced: Bool {
        get { return underlyingIsAppLockForced }
        set(value) { underlyingIsAppLockForced = value }
    }

    public var underlyingIsAppLockForced: Bool!

    // MARK: - appLockTimeout

    public var appLockTimeout: UInt {
        get { return underlyingAppLockTimeout }
        set(value) { underlyingAppLockTimeout = value }
    }

    public var underlyingAppLockTimeout: UInt!

    // MARK: - isCustomAppLockPasscodeSet

    public var isCustomAppLockPasscodeSet: Bool {
        get { return underlyingIsCustomAppLockPasscodeSet }
        set(value) { underlyingIsCustomAppLockPasscodeSet = value }
    }

    public var underlyingIsCustomAppLockPasscodeSet: Bool!

    // MARK: - requireCustomAppLockPasscode

    public var requireCustomAppLockPasscode: Bool {
        get { return underlyingRequireCustomAppLockPasscode }
        set(value) { underlyingRequireCustomAppLockPasscode = value }
    }

    public var underlyingRequireCustomAppLockPasscode: Bool!

    // MARK: - shouldNotifyUserOfDisabledAppLock

    public var shouldNotifyUserOfDisabledAppLock: Bool {
        get { return underlyingShouldNotifyUserOfDisabledAppLock }
        set(value) { underlyingShouldNotifyUserOfDisabledAppLock = value }
    }

    public var underlyingShouldNotifyUserOfDisabledAppLock: Bool!

    // MARK: - needsToNotifyUserOfAppLockConfiguration

    public var needsToNotifyUserOfAppLockConfiguration: Bool {
        get { return underlyingNeedsToNotifyUserOfAppLockConfiguration }
        set(value) { underlyingNeedsToNotifyUserOfAppLockConfiguration = value }
    }

    public var underlyingNeedsToNotifyUserOfAppLockConfiguration: Bool!

    // MARK: - conversationDirectory

    public var conversationDirectory: ConversationDirectoryType {
        get { return underlyingConversationDirectory }
        set(value) { underlyingConversationDirectory = value }
    }

    public var underlyingConversationDirectory: ConversationDirectoryType!

    // MARK: - selfUser

    public var selfUser: UserType {
        get { return underlyingSelfUser }
        set(value) { underlyingSelfUser = value }
    }

    public var underlyingSelfUser: UserType!

    // MARK: - selfLegalHoldSubject

    public var selfLegalHoldSubject: SelfUserType {
        get { return underlyingSelfLegalHoldSubject }
        set(value) { underlyingSelfLegalHoldSubject = value }
    }

    public var underlyingSelfLegalHoldSubject: SelfUserType!

    // MARK: - isNotificationContentHidden

    public var isNotificationContentHidden: Bool {
        get { return underlyingIsNotificationContentHidden }
        set(value) { underlyingIsNotificationContentHidden = value }
    }

    public var underlyingIsNotificationContentHidden: Bool!

    // MARK: - encryptMessagesAtRest

    public var encryptMessagesAtRest: Bool {
        get { return underlyingEncryptMessagesAtRest }
        set(value) { underlyingEncryptMessagesAtRest = value }
    }

    public var underlyingEncryptMessagesAtRest: Bool!

    // MARK: - ringingCallConversation

    public var ringingCallConversation: ZMConversation?

    // MARK: - maxAudioMessageLength

    public var maxAudioMessageLength: TimeInterval {
        get { return underlyingMaxAudioMessageLength }
        set(value) { underlyingMaxAudioMessageLength = value }
    }

    public var underlyingMaxAudioMessageLength: TimeInterval!

    // MARK: - maxUploadFileSize

    public var maxUploadFileSize: UInt64 {
        get { return underlyingMaxUploadFileSize }
        set(value) { underlyingMaxUploadFileSize = value }
    }

    public var underlyingMaxUploadFileSize: UInt64!

    // MARK: - maxVideoLength

    public var maxVideoLength: TimeInterval {
        get { return underlyingMaxVideoLength }
        set(value) { underlyingMaxVideoLength = value }
    }

    public var underlyingMaxVideoLength: TimeInterval!

    // MARK: - networkState

    public var networkState: ZMNetworkState {
        get { return underlyingNetworkState }
        set(value) { underlyingNetworkState = value }
    }

    public var underlyingNetworkState: ZMNetworkState!

    // MARK: - selfUserClient

    public var selfUserClient: UserClient?

    // MARK: - e2eiFeature

    public var e2eiFeature: Feature.E2EI {
        get { return underlyingE2eiFeature }
        set(value) { underlyingE2eiFeature = value }
    }

    public var underlyingE2eiFeature: Feature.E2EI!

    // MARK: - getUserClientFingerprint

    public var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol {
        get { return underlyingGetUserClientFingerprint }
        set(value) { underlyingGetUserClientFingerprint = value }
    }

    public var underlyingGetUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol!

    // MARK: - isUserE2EICertifiedUseCase

    public var isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol {
        get { return underlyingIsUserE2EICertifiedUseCase }
        set(value) { underlyingIsUserE2EICertifiedUseCase = value }
    }

    public var underlyingIsUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol!

    // MARK: - isSelfUserE2EICertifiedUseCase

    public var isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol {
        get { return underlyingIsSelfUserE2EICertifiedUseCase }
        set(value) { underlyingIsSelfUserE2EICertifiedUseCase = value }
    }

    public var underlyingIsSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol!

    // MARK: - getIsE2eIdentityEnabled

    public var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol {
        get { return underlyingGetIsE2eIdentityEnabled }
        set(value) { underlyingGetIsE2eIdentityEnabled = value }
    }

    public var underlyingGetIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol!

    // MARK: - getE2eIdentityCertificates

    public var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol {
        get { return underlyingGetE2eIdentityCertificates }
        set(value) { underlyingGetE2eIdentityCertificates = value }
    }

    public var underlyingGetE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol!

    // MARK: - enrollE2EICertificate

    public var enrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol {
        get { return underlyingEnrollE2EICertificate }
        set(value) { underlyingEnrollE2EICertificate = value }
    }

    public var underlyingEnrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol!

    // MARK: - updateMLSGroupVerificationStatus

    public var updateMLSGroupVerificationStatus: UpdateMLSGroupVerificationStatusUseCaseProtocol {
        get { return underlyingUpdateMLSGroupVerificationStatus }
        set(value) { underlyingUpdateMLSGroupVerificationStatus = value }
    }

    public var underlyingUpdateMLSGroupVerificationStatus: UpdateMLSGroupVerificationStatusUseCaseProtocol!

    // MARK: - lastE2EIUpdateDateRepository

    public var lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?


    // MARK: - unlockDatabase

    public var unlockDatabase_Invocations: [Void] = []
    public var unlockDatabase_MockError: Error?
    public var unlockDatabase_MockMethod: (() throws -> Void)?

    public func unlockDatabase() throws {
        unlockDatabase_Invocations.append(())

        if let error = unlockDatabase_MockError {
            throw error
        }

        guard let mock = unlockDatabase_MockMethod else {
            fatalError("no mock for `unlockDatabase`")
        }

        try mock()
    }

    // MARK: - openAppLock

    public var openAppLock_Invocations: [Void] = []
    public var openAppLock_MockError: Error?
    public var openAppLock_MockMethod: (() throws -> Void)?

    public func openAppLock() throws {
        openAppLock_Invocations.append(())

        if let error = openAppLock_MockError {
            throw error
        }

        guard let mock = openAppLock_MockMethod else {
            fatalError("no mock for `openAppLock`")
        }

        try mock()
    }

    // MARK: - evaluateAppLockAuthentication

    public var evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_Invocations: [(passcodePreference: AppLockPasscodePreference, description: String, callback: (AppLockAuthenticationResult) -> Void)] = []
    public var evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_MockMethod: ((AppLockPasscodePreference, String, @escaping (AppLockAuthenticationResult) -> Void) -> Void)?

    public func evaluateAppLockAuthentication(passcodePreference: AppLockPasscodePreference, description: String, callback: @escaping (AppLockAuthenticationResult) -> Void) {
        evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_Invocations.append((passcodePreference: passcodePreference, description: description, callback: callback))

        guard let mock = evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_MockMethod else {
            fatalError("no mock for `evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback`")
        }

        mock(passcodePreference, description, callback)
    }

    // MARK: - evaluateAuthentication

    public var evaluateAuthenticationCustomPasscode_Invocations: [String] = []
    public var evaluateAuthenticationCustomPasscode_MockMethod: ((String) -> AppLockAuthenticationResult)?
    public var evaluateAuthenticationCustomPasscode_MockValue: AppLockAuthenticationResult?

    public func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        evaluateAuthenticationCustomPasscode_Invocations.append(customPasscode)

        if let mock = evaluateAuthenticationCustomPasscode_MockMethod {
            return mock(customPasscode)
        } else if let mock = evaluateAuthenticationCustomPasscode_MockValue {
            return mock
        } else {
            fatalError("no mock for `evaluateAuthenticationCustomPasscode`")
        }
    }

    // MARK: - deleteAppLockPasscode

    public var deleteAppLockPasscode_Invocations: [Void] = []
    public var deleteAppLockPasscode_MockError: Error?
    public var deleteAppLockPasscode_MockMethod: (() throws -> Void)?

    public func deleteAppLockPasscode() throws {
        deleteAppLockPasscode_Invocations.append(())

        if let error = deleteAppLockPasscode_MockError {
            throw error
        }

        guard let mock = deleteAppLockPasscode_MockMethod else {
            fatalError("no mock for `deleteAppLockPasscode`")
        }

        try mock()
    }

    // MARK: - perform

    public var perform_Invocations: [() -> Void] = []
    public var perform_MockMethod: ((@escaping () -> Void) -> Void)?

    public func perform(_ changes: @escaping () -> Void) {
        perform_Invocations.append(changes)

        guard let mock = perform_MockMethod else {
            fatalError("no mock for `perform`")
        }

        mock(changes)
    }

    // MARK: - enqueue

    public var enqueue_Invocations: [() -> Void] = []
    public var enqueue_MockMethod: ((@escaping () -> Void) -> Void)?

    public func enqueue(_ changes: @escaping () -> Void) {
        enqueue_Invocations.append(changes)

        guard let mock = enqueue_MockMethod else {
            fatalError("no mock for `enqueue`")
        }

        mock(changes)
    }

    // MARK: - enqueue

    public var enqueueCompletionHandler_Invocations: [(changes: () -> Void, completionHandler: (() -> Void)?)] = []
    public var enqueueCompletionHandler_MockMethod: ((@escaping () -> Void, (() -> Void)?) -> Void)?

    public func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        enqueueCompletionHandler_Invocations.append((changes: changes, completionHandler: completionHandler))

        guard let mock = enqueueCompletionHandler_MockMethod else {
            fatalError("no mock for `enqueueCompletionHandler`")
        }

        mock(changes, completionHandler)
    }

    // MARK: - setEncryptionAtRest

    public var setEncryptionAtRestEnabledSkipMigration_Invocations: [(enabled: Bool, skipMigration: Bool)] = []
    public var setEncryptionAtRestEnabledSkipMigration_MockError: Error?
    public var setEncryptionAtRestEnabledSkipMigration_MockMethod: ((Bool, Bool) throws -> Void)?

    public func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws {
        setEncryptionAtRestEnabledSkipMigration_Invocations.append((enabled: enabled, skipMigration: skipMigration))

        if let error = setEncryptionAtRestEnabledSkipMigration_MockError {
            throw error
        }

        guard let mock = setEncryptionAtRestEnabledSkipMigration_MockMethod else {
            fatalError("no mock for `setEncryptionAtRestEnabledSkipMigration`")
        }

        try mock(enabled, skipMigration)
    }

    // MARK: - addUserObserver

    public var addUserObserverFor_Invocations: [(observer: UserObserving, user: UserType)] = []
    public var addUserObserverFor_MockMethod: ((UserObserving, UserType) -> NSObjectProtocol?)?
    public var addUserObserverFor_MockValue: NSObjectProtocol??

    public func addUserObserver(_ observer: UserObserving, for user: UserType) -> NSObjectProtocol? {
        addUserObserverFor_Invocations.append((observer: observer, user: user))

        if let mock = addUserObserverFor_MockMethod {
            return mock(observer, user)
        } else if let mock = addUserObserverFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `addUserObserverFor`")
        }
    }

    // MARK: - addUserObserver

    public var addUserObserver_Invocations: [UserObserving] = []
    public var addUserObserver_MockMethod: ((UserObserving) -> NSObjectProtocol)?
    public var addUserObserver_MockValue: NSObjectProtocol?

    public func addUserObserver(_ observer: UserObserving) -> NSObjectProtocol {
        addUserObserver_Invocations.append(observer)

        if let mock = addUserObserver_MockMethod {
            return mock(observer)
        } else if let mock = addUserObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addUserObserver`")
        }
    }

    // MARK: - addMessageObserver

    public var addMessageObserverFor_Invocations: [(observer: ZMMessageObserver, message: ZMConversationMessage)] = []
    public var addMessageObserverFor_MockMethod: ((ZMMessageObserver, ZMConversationMessage) -> NSObjectProtocol)?
    public var addMessageObserverFor_MockValue: NSObjectProtocol?

    public func addMessageObserver(_ observer: ZMMessageObserver, for message: ZMConversationMessage) -> NSObjectProtocol {
        addMessageObserverFor_Invocations.append((observer: observer, message: message))

        if let mock = addMessageObserverFor_MockMethod {
            return mock(observer, message)
        } else if let mock = addMessageObserverFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `addMessageObserverFor`")
        }
    }

    // MARK: - addConferenceCallingUnavailableObserver

    public var addConferenceCallingUnavailableObserver_Invocations: [ConferenceCallingUnavailableObserver] = []
    public var addConferenceCallingUnavailableObserver_MockMethod: ((ConferenceCallingUnavailableObserver) -> Any)?
    public var addConferenceCallingUnavailableObserver_MockValue: Any?

    public func addConferenceCallingUnavailableObserver(_ observer: ConferenceCallingUnavailableObserver) -> Any {
        addConferenceCallingUnavailableObserver_Invocations.append(observer)

        if let mock = addConferenceCallingUnavailableObserver_MockMethod {
            return mock(observer)
        } else if let mock = addConferenceCallingUnavailableObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConferenceCallingUnavailableObserver`")
        }
    }

    // MARK: - addConferenceCallStateObserver

    public var addConferenceCallStateObserver_Invocations: [WireCallCenterCallStateObserver] = []
    public var addConferenceCallStateObserver_MockMethod: ((WireCallCenterCallStateObserver) -> Any)?
    public var addConferenceCallStateObserver_MockValue: Any?

    public func addConferenceCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any {
        addConferenceCallStateObserver_Invocations.append(observer)

        if let mock = addConferenceCallStateObserver_MockMethod {
            return mock(observer)
        } else if let mock = addConferenceCallStateObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConferenceCallStateObserver`")
        }
    }

    // MARK: - addConferenceCallErrorObserver

    public var addConferenceCallErrorObserver_Invocations: [WireCallCenterCallErrorObserver] = []
    public var addConferenceCallErrorObserver_MockMethod: ((WireCallCenterCallErrorObserver) -> Any)?
    public var addConferenceCallErrorObserver_MockValue: Any?

    public func addConferenceCallErrorObserver(_ observer: WireCallCenterCallErrorObserver) -> Any {
        addConferenceCallErrorObserver_Invocations.append(observer)

        if let mock = addConferenceCallErrorObserver_MockMethod {
            return mock(observer)
        } else if let mock = addConferenceCallErrorObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConferenceCallErrorObserver`")
        }
    }

    // MARK: - addConversationListObserver

    public var addConversationListObserverFor_Invocations: [(observer: ZMConversationListObserver, list: ZMConversationList)] = []
    public var addConversationListObserverFor_MockMethod: ((ZMConversationListObserver, ZMConversationList) -> NSObjectProtocol)?
    public var addConversationListObserverFor_MockValue: NSObjectProtocol?

    public func addConversationListObserver(_ observer: ZMConversationListObserver, for list: ZMConversationList) -> NSObjectProtocol {
        addConversationListObserverFor_Invocations.append((observer: observer, list: list))

        if let mock = addConversationListObserverFor_MockMethod {
            return mock(observer, list)
        } else if let mock = addConversationListObserverFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConversationListObserverFor`")
        }
    }

    // MARK: - conversationList

    public var conversationList_Invocations: [Void] = []
    public var conversationList_MockMethod: (() -> ZMConversationList)?
    public var conversationList_MockValue: ZMConversationList?

    public func conversationList() -> ZMConversationList {
        conversationList_Invocations.append(())

        if let mock = conversationList_MockMethod {
            return mock()
        } else if let mock = conversationList_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationList`")
        }
    }

    // MARK: - pendingConnectionConversationsInUserSession

    public var pendingConnectionConversationsInUserSession_Invocations: [Void] = []
    public var pendingConnectionConversationsInUserSession_MockMethod: (() -> ZMConversationList)?
    public var pendingConnectionConversationsInUserSession_MockValue: ZMConversationList?

    public func pendingConnectionConversationsInUserSession() -> ZMConversationList {
        pendingConnectionConversationsInUserSession_Invocations.append(())

        if let mock = pendingConnectionConversationsInUserSession_MockMethod {
            return mock()
        } else if let mock = pendingConnectionConversationsInUserSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `pendingConnectionConversationsInUserSession`")
        }
    }

    // MARK: - archivedConversationsInUserSession

    public var archivedConversationsInUserSession_Invocations: [Void] = []
    public var archivedConversationsInUserSession_MockMethod: (() -> ZMConversationList)?
    public var archivedConversationsInUserSession_MockValue: ZMConversationList?

    public func archivedConversationsInUserSession() -> ZMConversationList {
        archivedConversationsInUserSession_Invocations.append(())

        if let mock = archivedConversationsInUserSession_MockMethod {
            return mock()
        } else if let mock = archivedConversationsInUserSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `archivedConversationsInUserSession`")
        }
    }

    // MARK: - acknowledgeFeatureChange

    public var acknowledgeFeatureChangeFor_Invocations: [Feature.Name] = []
    public var acknowledgeFeatureChangeFor_MockMethod: ((Feature.Name) -> Void)?

    public func acknowledgeFeatureChange(for feature: Feature.Name) {
        acknowledgeFeatureChangeFor_Invocations.append(feature)

        guard let mock = acknowledgeFeatureChangeFor_MockMethod else {
            fatalError("no mock for `acknowledgeFeatureChangeFor`")
        }

        mock(feature)
    }

    // MARK: - fetchMarketingConsent

    public var fetchMarketingConsentCompletion_Invocations: [(Result<Bool, Error>) -> Void] = []
    public var fetchMarketingConsentCompletion_MockMethod: ((@escaping (Result<Bool, Error>) -> Void) -> Void)?

    public func fetchMarketingConsent(completion: @escaping (Result<Bool, Error>) -> Void) {
        fetchMarketingConsentCompletion_Invocations.append(completion)

        guard let mock = fetchMarketingConsentCompletion_MockMethod else {
            fatalError("no mock for `fetchMarketingConsentCompletion`")
        }

        mock(completion)
    }

    // MARK: - setMarketingConsent

    public var setMarketingConsentGrantedCompletion_Invocations: [(granted: Bool, completion: (Result<Void, Error>) -> Void)] = []
    public var setMarketingConsentGrantedCompletion_MockMethod: ((Bool, @escaping (Result<Void, Error>) -> Void) -> Void)?

    public func setMarketingConsent(granted: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        setMarketingConsentGrantedCompletion_Invocations.append((granted: granted, completion: completion))

        guard let mock = setMarketingConsentGrantedCompletion_MockMethod else {
            fatalError("no mock for `setMarketingConsentGrantedCompletion`")
        }

        mock(granted, completion)
    }

    // MARK: - classification

    public var classificationUsersConversationDomain_Invocations: [(users: [UserType], conversationDomain: String?)] = []
    public var classificationUsersConversationDomain_MockMethod: (([UserType], String?) -> SecurityClassification?)?
    public var classificationUsersConversationDomain_MockValue: SecurityClassification??

    public func classification(users: [UserType], conversationDomain: String?) -> SecurityClassification? {
        classificationUsersConversationDomain_Invocations.append((users: users, conversationDomain: conversationDomain))

        if let mock = classificationUsersConversationDomain_MockMethod {
            return mock(users, conversationDomain)
        } else if let mock = classificationUsersConversationDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `classificationUsersConversationDomain`")
        }
    }

    // MARK: - proxiedRequest

    public var proxiedRequestPathMethodTypeCallback_Invocations: [(path: String, method: ZMTransportRequestMethod, type: ProxiedRequestType, callback: ProxyRequestCallback?)] = []
    public var proxiedRequestPathMethodTypeCallback_MockMethod: ((String, ZMTransportRequestMethod, ProxiedRequestType, ProxyRequestCallback?) -> ProxyRequest)?
    public var proxiedRequestPathMethodTypeCallback_MockValue: ProxyRequest?

    public func proxiedRequest(path: String, method: ZMTransportRequestMethod, type: ProxiedRequestType, callback: ProxyRequestCallback?) -> ProxyRequest {
        proxiedRequestPathMethodTypeCallback_Invocations.append((path: path, method: method, type: type, callback: callback))

        if let mock = proxiedRequestPathMethodTypeCallback_MockMethod {
            return mock(path, method, type, callback)
        } else if let mock = proxiedRequestPathMethodTypeCallback_MockValue {
            return mock
        } else {
            fatalError("no mock for `proxiedRequestPathMethodTypeCallback`")
        }
    }

    // MARK: - cancelProxiedRequest

    public var cancelProxiedRequest_Invocations: [ProxyRequest] = []
    public var cancelProxiedRequest_MockMethod: ((ProxyRequest) -> Void)?

    public func cancelProxiedRequest(_ request: ProxyRequest) {
        cancelProxiedRequest_Invocations.append(request)

        guard let mock = cancelProxiedRequest_MockMethod else {
            fatalError("no mock for `cancelProxiedRequest`")
        }

        mock(request)
    }

    // MARK: - fetchAllClients

    public var fetchAllClients_Invocations: [Void] = []
    public var fetchAllClients_MockMethod: (() -> Void)?

    public func fetchAllClients() {
        fetchAllClients_Invocations.append(())

        guard let mock = fetchAllClients_MockMethod else {
            fatalError("no mock for `fetchAllClients`")
        }

        mock()
    }

    // MARK: - makeGetMLSFeatureUseCase

    public var makeGetMLSFeatureUseCase_Invocations: [Void] = []
    public var makeGetMLSFeatureUseCase_MockMethod: (() -> GetMLSFeatureUseCaseProtocol)?
    public var makeGetMLSFeatureUseCase_MockValue: GetMLSFeatureUseCaseProtocol?

    public func makeGetMLSFeatureUseCase() -> GetMLSFeatureUseCaseProtocol {
        makeGetMLSFeatureUseCase_Invocations.append(())

        if let mock = makeGetMLSFeatureUseCase_MockMethod {
            return mock()
        } else if let mock = makeGetMLSFeatureUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeGetMLSFeatureUseCase`")
        }
    }

    // MARK: - fetchSelfConversationMLSGroupID

    public var fetchSelfConversationMLSGroupID_Invocations: [Void] = []
    public var fetchSelfConversationMLSGroupID_MockMethod: (() async -> MLSGroupID?)?
    public var fetchSelfConversationMLSGroupID_MockValue: MLSGroupID??

    public func fetchSelfConversationMLSGroupID() async -> MLSGroupID? {
        fetchSelfConversationMLSGroupID_Invocations.append(())

        if let mock = fetchSelfConversationMLSGroupID_MockMethod {
            return await mock()
        } else if let mock = fetchSelfConversationMLSGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfConversationMLSGroupID`")
        }
    }

    // MARK: - e2eIdentityUpdateCertificateUpdateStatus

    public var e2eIdentityUpdateCertificateUpdateStatus_Invocations: [Void] = []
    public var e2eIdentityUpdateCertificateUpdateStatus_MockMethod: (() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol?)?
    public var e2eIdentityUpdateCertificateUpdateStatus_MockValue: E2EIdentityCertificateUpdateStatusUseCaseProtocol??

    public func e2eIdentityUpdateCertificateUpdateStatus() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol? {
        e2eIdentityUpdateCertificateUpdateStatus_Invocations.append(())

        if let mock = e2eIdentityUpdateCertificateUpdateStatus_MockMethod {
            return mock()
        } else if let mock = e2eIdentityUpdateCertificateUpdateStatus_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eIdentityUpdateCertificateUpdateStatus`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
