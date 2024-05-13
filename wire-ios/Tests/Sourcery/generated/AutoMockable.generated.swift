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

import WireDataModel
import WireSyncEngine

@testable import Wire





















public class MockAccountSelector: AccountSelector {

    // MARK: - Life cycle

    public init() {}

    // MARK: - currentAccount

    public var currentAccount: Account?


    // MARK: - switchTo

    public var switchToAccount_Invocations: [Account] = []
    public var switchToAccount_MockMethod: ((Account) -> Void)?

    public func switchTo(account: Account) {
        switchToAccount_Invocations.append(account)

        guard let mock = switchToAccount_MockMethod else {
            fatalError("no mock for `switchToAccount`")
        }

        mock(account)
    }

    // MARK: - switchTo

    public var switchToAccountCompletion_Invocations: [(account: Account, completion: ((UserSession?) -> Void)?)] = []
    public var switchToAccountCompletion_MockMethod: ((Account, ((UserSession?) -> Void)?) -> Void)?

    public func switchTo(account: Account, completion: ((UserSession?) -> Void)?) {
        switchToAccountCompletion_Invocations.append((account: account, completion: completion))

        guard let mock = switchToAccountCompletion_MockMethod else {
            fatalError("no mock for `switchToAccountCompletion`")
        }

        mock(account, completion)
    }

}

class MockBackupSource: BackupSource {

    // MARK: - Life cycle



    // MARK: - backupActiveAccount

    var backupActiveAccountPasswordCompletion_Invocations: [(password: String, completion: (Result<URL, Error>) -> Void)] = []
    var backupActiveAccountPasswordCompletion_MockMethod: ((String, @escaping (Result<URL, Error>) -> Void) -> Void)?

    func backupActiveAccount(password: String, completion: @escaping (Result<URL, Error>) -> Void) {
        backupActiveAccountPasswordCompletion_Invocations.append((password: password, completion: completion))

        guard let mock = backupActiveAccountPasswordCompletion_MockMethod else {
            fatalError("no mock for `backupActiveAccountPasswordCompletion`")
        }

        mock(password, completion)
    }

    // MARK: - clearPreviousBackups

    var clearPreviousBackups_Invocations: [Void] = []
    var clearPreviousBackups_MockMethod: (() -> Void)?

    func clearPreviousBackups() {
        clearPreviousBackups_Invocations.append(())

        guard let mock = clearPreviousBackups_MockMethod else {
            fatalError("no mock for `clearPreviousBackups`")
        }

        mock()
    }

}

class MockConversationUserClientDetailsActions: ConversationUserClientDetailsActions {

    // MARK: - Life cycle



    // MARK: - showMyDevice

    var showMyDevice_Invocations: [Void] = []
    var showMyDevice_MockMethod: (() -> Void)?

    func showMyDevice() {
        showMyDevice_Invocations.append(())

        guard let mock = showMyDevice_MockMethod else {
            fatalError("no mock for `showMyDevice`")
        }

        mock()
    }

    // MARK: - howToDoThat

    var howToDoThat_Invocations: [Void] = []
    var howToDoThat_MockMethod: (() -> Void)?

    func howToDoThat() {
        howToDoThat_Invocations.append(())

        guard let mock = howToDoThat_MockMethod else {
            fatalError("no mock for `howToDoThat`")
        }

        mock()
    }

}

class MockDeviceDetailsViewActions: DeviceDetailsViewActions {

    // MARK: - Life cycle


    // MARK: - isSelfClient

    var isSelfClient: Bool {
        get { return underlyingIsSelfClient }
        set(value) { underlyingIsSelfClient = value }
    }

    var underlyingIsSelfClient: Bool!

    // MARK: - isProcessing

    var isProcessing: ((Bool) -> Void)?


    // MARK: - enrollClient

    var enrollClient_Invocations: [Void] = []
    var enrollClient_MockError: Error?
    var enrollClient_MockMethod: (() async throws -> String)?
    var enrollClient_MockValue: String?

    func enrollClient() async throws -> String {
        enrollClient_Invocations.append(())

        if let error = enrollClient_MockError {
            throw error
        }

        if let mock = enrollClient_MockMethod {
            return try await mock()
        } else if let mock = enrollClient_MockValue {
            return mock
        } else {
            fatalError("no mock for `enrollClient`")
        }
    }

    // MARK: - removeDevice

    var removeDevice_Invocations: [Void] = []
    var removeDevice_MockMethod: (() async -> Bool)?
    var removeDevice_MockValue: Bool?

    func removeDevice() async -> Bool {
        removeDevice_Invocations.append(())

        if let mock = removeDevice_MockMethod {
            return await mock()
        } else if let mock = removeDevice_MockValue {
            return mock
        } else {
            fatalError("no mock for `removeDevice`")
        }
    }

    // MARK: - resetSession

    var resetSession_Invocations: [Void] = []
    var resetSession_MockMethod: (() -> Void)?

    func resetSession() {
        resetSession_Invocations.append(())

        guard let mock = resetSession_MockMethod else {
            fatalError("no mock for `resetSession`")
        }

        mock()
    }

    // MARK: - updateVerified

    var updateVerified_Invocations: [Bool] = []
    var updateVerified_MockMethod: ((Bool) async -> Bool)?
    var updateVerified_MockValue: Bool?

    func updateVerified(_ value: Bool) async -> Bool {
        updateVerified_Invocations.append(value)

        if let mock = updateVerified_MockMethod {
            return await mock(value)
        } else if let mock = updateVerified_MockValue {
            return mock
        } else {
            fatalError("no mock for `updateVerified`")
        }
    }

    // MARK: - copyToClipboard

    var copyToClipboard_Invocations: [String] = []
    var copyToClipboard_MockMethod: ((String) -> Void)?

    func copyToClipboard(_ value: String) {
        copyToClipboard_Invocations.append(value)

        guard let mock = copyToClipboard_MockMethod else {
            fatalError("no mock for `copyToClipboard`")
        }

        mock(value)
    }

    // MARK: - downloadE2EIdentityCertificate

    var downloadE2EIdentityCertificateCertificate_Invocations: [E2eIdentityCertificate] = []
    var downloadE2EIdentityCertificateCertificate_MockMethod: ((E2eIdentityCertificate) -> Void)?

    func downloadE2EIdentityCertificate(certificate: E2eIdentityCertificate) {
        downloadE2EIdentityCertificateCertificate_Invocations.append(certificate)

        guard let mock = downloadE2EIdentityCertificateCertificate_MockMethod else {
            fatalError("no mock for `downloadE2EIdentityCertificateCertificate`")
        }

        mock(certificate)
    }

    // MARK: - getProteusFingerPrint

    var getProteusFingerPrint_Invocations: [Void] = []
    var getProteusFingerPrint_MockMethod: (() async -> String)?
    var getProteusFingerPrint_MockValue: String?

    func getProteusFingerPrint() async -> String {
        getProteusFingerPrint_Invocations.append(())

        if let mock = getProteusFingerPrint_MockMethod {
            return await mock()
        } else if let mock = getProteusFingerPrint_MockValue {
            return mock
        } else {
            fatalError("no mock for `getProteusFingerPrint`")
        }
    }

}

class MockImageTransformer: ImageTransformer {

    // MARK: - Life cycle



    // MARK: - adjustInputSaturation

    var adjustInputSaturationValueImage_Invocations: [(value: CGFloat, image: UIImage)] = []
    var adjustInputSaturationValueImage_MockMethod: ((CGFloat, UIImage) -> UIImage?)?
    var adjustInputSaturationValueImage_MockValue: UIImage??

    func adjustInputSaturation(value: CGFloat, image: UIImage) -> UIImage? {
        adjustInputSaturationValueImage_Invocations.append((value: value, image: image))

        if let mock = adjustInputSaturationValueImage_MockMethod {
            return mock(value, image)
        } else if let mock = adjustInputSaturationValueImage_MockValue {
            return mock
        } else {
            fatalError("no mock for `adjustInputSaturationValueImage`")
        }
    }

}

class MockProfileActionsFactoryProtocol: ProfileActionsFactoryProtocol {

    // MARK: - Life cycle



    // MARK: - makeActionsList

    var makeActionsListCompletion_Invocations: [([ProfileAction]) -> Void] = []
    var makeActionsListCompletion_MockMethod: ((@escaping ([ProfileAction]) -> Void) -> Void)?

    func makeActionsList(completion: @escaping ([ProfileAction]) -> Void) {
        makeActionsListCompletion_Invocations.append(completion)

        guard let mock = makeActionsListCompletion_MockMethod else {
            fatalError("no mock for `makeActionsListCompletion`")
        }

        mock(completion)
    }

}

class MockProfileViewControllerViewModelDelegate: ProfileViewControllerViewModelDelegate {

    // MARK: - Life cycle



    // MARK: - setupNavigationItems

    var setupNavigationItems_Invocations: [Void] = []
    var setupNavigationItems_MockMethod: (() -> Void)?

    func setupNavigationItems() {
        setupNavigationItems_Invocations.append(())

        guard let mock = setupNavigationItems_MockMethod else {
            fatalError("no mock for `setupNavigationItems`")
        }

        mock()
    }

    // MARK: - updateFooterActionsViews

    var updateFooterActionsViews_Invocations: [[ProfileAction]] = []
    var updateFooterActionsViews_MockMethod: (([ProfileAction]) -> Void)?

    func updateFooterActionsViews(_ actions: [ProfileAction]) {
        updateFooterActionsViews_Invocations.append(actions)

        guard let mock = updateFooterActionsViews_MockMethod else {
            fatalError("no mock for `updateFooterActionsViews`")
        }

        mock(actions)
    }

    // MARK: - updateIncomingRequestFooter

    var updateIncomingRequestFooter_Invocations: [Void] = []
    var updateIncomingRequestFooter_MockMethod: (() -> Void)?

    func updateIncomingRequestFooter() {
        updateIncomingRequestFooter_Invocations.append(())

        guard let mock = updateIncomingRequestFooter_MockMethod else {
            fatalError("no mock for `updateIncomingRequestFooter`")
        }

        mock()
    }

    // MARK: - returnToPreviousScreen

    var returnToPreviousScreen_Invocations: [Void] = []
    var returnToPreviousScreen_MockMethod: (() -> Void)?

    func returnToPreviousScreen() {
        returnToPreviousScreen_Invocations.append(())

        guard let mock = returnToPreviousScreen_MockMethod else {
            fatalError("no mock for `returnToPreviousScreen`")
        }

        mock()
    }

    // MARK: - presentError

    var presentError_Invocations: [LocalizedError] = []
    var presentError_MockMethod: ((LocalizedError) -> Void)?

    func presentError(_ error: LocalizedError) {
        presentError_Invocations.append(error)

        guard let mock = presentError_MockMethod else {
            fatalError("no mock for `presentError`")
        }

        mock(error)
    }

    // MARK: - presentConversationCreationError

    var presentConversationCreationErrorUsername_Invocations: [String] = []
    var presentConversationCreationErrorUsername_MockMethod: ((String) -> Void)?

    func presentConversationCreationError(username: String) {
        presentConversationCreationErrorUsername_Invocations.append(username)

        guard let mock = presentConversationCreationErrorUsername_MockMethod else {
            fatalError("no mock for `presentConversationCreationErrorUsername`")
        }

        mock(username)
    }

    // MARK: - startAnimatingActivity

    var startAnimatingActivity_Invocations: [Void] = []
    var startAnimatingActivity_MockMethod: (() -> Void)?

    func startAnimatingActivity() {
        startAnimatingActivity_Invocations.append(())

        guard let mock = startAnimatingActivity_MockMethod else {
            fatalError("no mock for `startAnimatingActivity`")
        }

        mock()
    }

    // MARK: - stopAnimatingActivity

    var stopAnimatingActivity_Invocations: [Void] = []
    var stopAnimatingActivity_MockMethod: (() -> Void)?

    func stopAnimatingActivity() {
        stopAnimatingActivity_Invocations.append(())

        guard let mock = stopAnimatingActivity_MockMethod else {
            fatalError("no mock for `stopAnimatingActivity`")
        }

        mock()
    }

}

class MockProfileViewControllerViewModeling: ProfileViewControllerViewModeling {

    // MARK: - Life cycle


    // MARK: - classification

    var classification: SecurityClassification?

    // MARK: - userSet

    var userSet: UserSet {
        get { return underlyingUserSet }
        set(value) { underlyingUserSet = value }
    }

    var underlyingUserSet: UserSet!

    // MARK: - userSession

    var userSession: UserSession {
        get { return underlyingUserSession }
        set(value) { underlyingUserSession = value }
    }

    var underlyingUserSession: UserSession!

    // MARK: - user

    var user: UserType {
        get { return underlyingUser }
        set(value) { underlyingUser = value }
    }

    var underlyingUser: UserType!

    // MARK: - viewer

    var viewer: UserType {
        get { return underlyingViewer }
        set(value) { underlyingViewer = value }
    }

    var underlyingViewer: UserType!

    // MARK: - conversation

    var conversation: ZMConversation?

    // MARK: - context

    var context: ProfileViewControllerContext {
        get { return underlyingContext }
        set(value) { underlyingContext = value }
    }

    var underlyingContext: ProfileViewControllerContext!

    // MARK: - hasUserClientListTab

    var hasUserClientListTab: Bool {
        get { return underlyingHasUserClientListTab }
        set(value) { underlyingHasUserClientListTab = value }
    }

    var underlyingHasUserClientListTab: Bool!

    // MARK: - blockTitle

    var blockTitle: String?

    // MARK: - allBlockResult

    var allBlockResult: [BlockResult] = []

    // MARK: - hasLegalHoldItem

    var hasLegalHoldItem: Bool {
        get { return underlyingHasLegalHoldItem }
        set(value) { underlyingHasLegalHoldItem = value }
    }

    var underlyingHasLegalHoldItem: Bool!

    // MARK: - incomingRequestFooterHidden

    var incomingRequestFooterHidden: Bool {
        get { return underlyingIncomingRequestFooterHidden }
        set(value) { underlyingIncomingRequestFooterHidden = value }
    }

    var underlyingIncomingRequestFooterHidden: Bool!


    // MARK: - updateActionsList

    var updateActionsList_Invocations: [Void] = []
    var updateActionsList_MockMethod: (() -> Void)?

    func updateActionsList() {
        updateActionsList_Invocations.append(())

        guard let mock = updateActionsList_MockMethod else {
            fatalError("no mock for `updateActionsList`")
        }

        mock()
    }

    // MARK: - sendConnectionRequest

    var sendConnectionRequest_Invocations: [Void] = []
    var sendConnectionRequest_MockMethod: (() -> Void)?

    func sendConnectionRequest() {
        sendConnectionRequest_Invocations.append(())

        guard let mock = sendConnectionRequest_MockMethod else {
            fatalError("no mock for `sendConnectionRequest`")
        }

        mock()
    }

    // MARK: - acceptConnectionRequest

    var acceptConnectionRequest_Invocations: [Void] = []
    var acceptConnectionRequest_MockMethod: (() -> Void)?

    func acceptConnectionRequest() {
        acceptConnectionRequest_Invocations.append(())

        guard let mock = acceptConnectionRequest_MockMethod else {
            fatalError("no mock for `acceptConnectionRequest`")
        }

        mock()
    }

    // MARK: - ignoreConnectionRequest

    var ignoreConnectionRequest_Invocations: [Void] = []
    var ignoreConnectionRequest_MockMethod: (() -> Void)?

    func ignoreConnectionRequest() {
        ignoreConnectionRequest_Invocations.append(())

        guard let mock = ignoreConnectionRequest_MockMethod else {
            fatalError("no mock for `ignoreConnectionRequest`")
        }

        mock()
    }

    // MARK: - cancelConnectionRequest

    var cancelConnectionRequestCompletion_Invocations: [Completion] = []
    var cancelConnectionRequestCompletion_MockMethod: ((@escaping Completion) -> Void)?

    func cancelConnectionRequest(completion: @escaping Completion) {
        cancelConnectionRequestCompletion_Invocations.append(completion)

        guard let mock = cancelConnectionRequestCompletion_MockMethod else {
            fatalError("no mock for `cancelConnectionRequestCompletion`")
        }

        mock(completion)
    }

    // MARK: - openOneToOneConversation

    var openOneToOneConversation_Invocations: [Void] = []
    var openOneToOneConversation_MockMethod: (() -> Void)?

    func openOneToOneConversation() {
        openOneToOneConversation_Invocations.append(())

        guard let mock = openOneToOneConversation_MockMethod else {
            fatalError("no mock for `openOneToOneConversation`")
        }

        mock()
    }

    // MARK: - startOneToOneConversation

    var startOneToOneConversation_Invocations: [Void] = []
    var startOneToOneConversation_MockMethod: (() -> Void)?

    func startOneToOneConversation() {
        startOneToOneConversation_Invocations.append(())

        guard let mock = startOneToOneConversation_MockMethod else {
            fatalError("no mock for `startOneToOneConversation`")
        }

        mock()
    }

    // MARK: - archiveConversation

    var archiveConversation_Invocations: [Void] = []
    var archiveConversation_MockMethod: (() -> Void)?

    func archiveConversation() {
        archiveConversation_Invocations.append(())

        guard let mock = archiveConversation_MockMethod else {
            fatalError("no mock for `archiveConversation`")
        }

        mock()
    }

    // MARK: - updateMute

    var updateMuteEnableNotifications_Invocations: [Bool] = []
    var updateMuteEnableNotifications_MockMethod: ((Bool) -> Void)?

    func updateMute(enableNotifications: Bool) {
        updateMuteEnableNotifications_Invocations.append(enableNotifications)

        guard let mock = updateMuteEnableNotifications_MockMethod else {
            fatalError("no mock for `updateMuteEnableNotifications`")
        }

        mock(enableNotifications)
    }

    // MARK: - handleNotificationResult

    var handleNotificationResult_Invocations: [NotificationResult] = []
    var handleNotificationResult_MockMethod: ((NotificationResult) -> Void)?

    func handleNotificationResult(_ result: NotificationResult) {
        handleNotificationResult_Invocations.append(result)

        guard let mock = handleNotificationResult_MockMethod else {
            fatalError("no mock for `handleNotificationResult`")
        }

        mock(result)
    }

    // MARK: - handleBlockAndUnblock

    var handleBlockAndUnblock_Invocations: [Void] = []
    var handleBlockAndUnblock_MockMethod: (() -> Void)?

    func handleBlockAndUnblock() {
        handleBlockAndUnblock_Invocations.append(())

        guard let mock = handleBlockAndUnblock_MockMethod else {
            fatalError("no mock for `handleBlockAndUnblock`")
        }

        mock()
    }

    // MARK: - handleDeleteResult

    var handleDeleteResult_Invocations: [ClearContentResult] = []
    var handleDeleteResult_MockMethod: ((ClearContentResult) -> Void)?

    func handleDeleteResult(_ result: ClearContentResult) {
        handleDeleteResult_Invocations.append(result)

        guard let mock = handleDeleteResult_MockMethod else {
            fatalError("no mock for `handleDeleteResult`")
        }

        mock(result)
    }

    // MARK: - transitionToListAndEnqueue

    var transitionToListAndEnqueueLeftViewControllerRevealed_Invocations: [(leftViewControllerRevealed: Bool, block: () -> Void)] = []
    var transitionToListAndEnqueueLeftViewControllerRevealed_MockMethod: ((Bool, @escaping () -> Void) -> Void)?

    func transitionToListAndEnqueue(leftViewControllerRevealed: Bool, _ block: @escaping () -> Void) {
        transitionToListAndEnqueueLeftViewControllerRevealed_Invocations.append((leftViewControllerRevealed: leftViewControllerRevealed, block: block))

        guard let mock = transitionToListAndEnqueueLeftViewControllerRevealed_MockMethod else {
            fatalError("no mock for `transitionToListAndEnqueueLeftViewControllerRevealed`")
        }

        mock(leftViewControllerRevealed, block)
    }

    // MARK: - setConversationTransitionClosure

    var setConversationTransitionClosure_Invocations: [(ZMConversation) -> Void] = []
    var setConversationTransitionClosure_MockMethod: ((@escaping (ZMConversation) -> Void) -> Void)?

    func setConversationTransitionClosure(_ closure: @escaping (ZMConversation) -> Void) {
        setConversationTransitionClosure_Invocations.append(closure)

        guard let mock = setConversationTransitionClosure_MockMethod else {
            fatalError("no mock for `setConversationTransitionClosure`")
        }

        mock(closure)
    }

    // MARK: - setDelegate

    var setDelegate_Invocations: [ProfileViewControllerViewModelDelegate] = []
    var setDelegate_MockMethod: ((ProfileViewControllerViewModelDelegate) -> Void)?

    func setDelegate(_ delegate: ProfileViewControllerViewModelDelegate) {
        setDelegate_Invocations.append(delegate)

        guard let mock = setDelegate_MockMethod else {
            fatalError("no mock for `setDelegate`")
        }

        mock(delegate)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
