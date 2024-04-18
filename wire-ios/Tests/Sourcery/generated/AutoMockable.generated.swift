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

@testable import Wire





















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

class MockConversationGuestOptionsViewModelDelegate: ConversationGuestOptionsViewModelDelegate {

    // MARK: - Life cycle



    // MARK: - viewModel

    var viewModelDidUpdateState_Invocations: [(viewModel: ConversationGuestOptionsViewModel, state: ConversationGuestOptionsViewModel.State)] = []
    var viewModelDidUpdateState_MockMethod: ((ConversationGuestOptionsViewModel, ConversationGuestOptionsViewModel.State) -> Void)?

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, didUpdateState state: ConversationGuestOptionsViewModel.State) {
        viewModelDidUpdateState_Invocations.append((viewModel: viewModel, state: state))

        guard let mock = viewModelDidUpdateState_MockMethod else {
            fatalError("no mock for `viewModelDidUpdateState`")
        }

        mock(viewModel, state)
    }

    // MARK: - viewModel

    var viewModelDidReceiveError_Invocations: [(viewModel: ConversationGuestOptionsViewModel, error: Error)] = []
    var viewModelDidReceiveError_MockMethod: ((ConversationGuestOptionsViewModel, Error) -> Void)?

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, didReceiveError error: Error) {
        viewModelDidReceiveError_Invocations.append((viewModel: viewModel, error: error))

        guard let mock = viewModelDidReceiveError_MockMethod else {
            fatalError("no mock for `viewModelDidReceiveError`")
        }

        mock(viewModel, error)
    }

    // MARK: - viewModel

    var viewModelSourceViewConfirmRemovingGuests_Invocations: [(viewModel: ConversationGuestOptionsViewModel, sourceView: UIView?, completion: (Bool) -> Void)] = []
    var viewModelSourceViewConfirmRemovingGuests_MockMethod: ((ConversationGuestOptionsViewModel, UIView?, @escaping (Bool) -> Void) -> UIAlertController?)?
    var viewModelSourceViewConfirmRemovingGuests_MockValue: UIAlertController??

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, sourceView: UIView?, confirmRemovingGuests completion: @escaping (Bool) -> Void) -> UIAlertController? {
        viewModelSourceViewConfirmRemovingGuests_Invocations.append((viewModel: viewModel, sourceView: sourceView, completion: completion))

        if let mock = viewModelSourceViewConfirmRemovingGuests_MockMethod {
            return mock(viewModel, sourceView, completion)
        } else if let mock = viewModelSourceViewConfirmRemovingGuests_MockValue {
            return mock
        } else {
            fatalError("no mock for `viewModelSourceViewConfirmRemovingGuests`")
        }
    }

    // MARK: - viewModel

    var viewModelSourceViewPresentGuestLinkTypeSelection_Invocations: [(viewModel: ConversationGuestOptionsViewModel, sourceView: UIView?, completion: (GuestLinkType) -> Void)] = []
    var viewModelSourceViewPresentGuestLinkTypeSelection_MockMethod: ((ConversationGuestOptionsViewModel, UIView?, @escaping (GuestLinkType) -> Void) -> Void)?

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, sourceView: UIView?, presentGuestLinkTypeSelection completion: @escaping (GuestLinkType) -> Void) {
        viewModelSourceViewPresentGuestLinkTypeSelection_Invocations.append((viewModel: viewModel, sourceView: sourceView, completion: completion))

        guard let mock = viewModelSourceViewPresentGuestLinkTypeSelection_MockMethod else {
            fatalError("no mock for `viewModelSourceViewPresentGuestLinkTypeSelection`")
        }

        mock(viewModel, sourceView, completion)
    }

    // MARK: - viewModel

    var viewModelSourceViewConfirmRevokingLink_Invocations: [(viewModel: ConversationGuestOptionsViewModel, sourceView: UIView?, completion: (Bool) -> Void)] = []
    var viewModelSourceViewConfirmRevokingLink_MockMethod: ((ConversationGuestOptionsViewModel, UIView?, @escaping (Bool) -> Void) -> Void)?

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, sourceView: UIView?, confirmRevokingLink completion: @escaping (Bool) -> Void) {
        viewModelSourceViewConfirmRevokingLink_Invocations.append((viewModel: viewModel, sourceView: sourceView, completion: completion))

        guard let mock = viewModelSourceViewConfirmRevokingLink_MockMethod else {
            fatalError("no mock for `viewModelSourceViewConfirmRevokingLink`")
        }

        mock(viewModel, sourceView, completion)
    }

    // MARK: - viewModel

    var viewModelWantsToShareMessageSourceView_Invocations: [(viewModel: ConversationGuestOptionsViewModel, message: String, sourceView: UIView?)] = []
    var viewModelWantsToShareMessageSourceView_MockMethod: ((ConversationGuestOptionsViewModel, String, UIView?) -> Void)?

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, wantsToShareMessage message: String, sourceView: UIView?) {
        viewModelWantsToShareMessageSourceView_Invocations.append((viewModel: viewModel, message: message, sourceView: sourceView))

        guard let mock = viewModelWantsToShareMessageSourceView_MockMethod else {
            fatalError("no mock for `viewModelWantsToShareMessageSourceView`")
        }

        mock(viewModel, message, sourceView)
    }

    // MARK: - viewModel

    var viewModelPresentCreateSecureGuestLinkAnimated_Invocations: [(viewModel: ConversationGuestOptionsViewModel, viewController: UIViewController, animated: Bool)] = []
    var viewModelPresentCreateSecureGuestLinkAnimated_MockMethod: ((ConversationGuestOptionsViewModel, UIViewController, Bool) -> Void)?

    func viewModel(_ viewModel: ConversationGuestOptionsViewModel, presentCreateSecureGuestLink viewController: UIViewController, animated: Bool) {
        viewModelPresentCreateSecureGuestLinkAnimated_Invocations.append((viewModel: viewModel, viewController: viewController, animated: animated))

        guard let mock = viewModelPresentCreateSecureGuestLinkAnimated_MockMethod else {
            fatalError("no mock for `viewModelPresentCreateSecureGuestLinkAnimated`")
        }

        mock(viewModel, viewController, animated)
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

class MockCreatePasswordSecuredLinkViewModelDelegate: CreatePasswordSecuredLinkViewModelDelegate {

    // MARK: - Life cycle



    // MARK: - viewModel

    var viewModelDidGeneratePassword_Invocations: [(viewModel: CreateSecureGuestLinkViewModel, password: String)] = []
    var viewModelDidGeneratePassword_MockMethod: ((CreateSecureGuestLinkViewModel, String) -> Void)?

    func viewModel(_ viewModel: CreateSecureGuestLinkViewModel, didGeneratePassword password: String) {
        viewModelDidGeneratePassword_Invocations.append((viewModel: viewModel, password: password))

        guard let mock = viewModelDidGeneratePassword_MockMethod else {
            fatalError("no mock for `viewModelDidGeneratePassword`")
        }

        mock(viewModel, password)
    }

    // MARK: - viewModelDidValidatePasswordSuccessfully

    var viewModelDidValidatePasswordSuccessfully_Invocations: [CreateSecureGuestLinkViewModel] = []
    var viewModelDidValidatePasswordSuccessfully_MockMethod: ((CreateSecureGuestLinkViewModel) -> Void)?

    func viewModelDidValidatePasswordSuccessfully(_ viewModel: CreateSecureGuestLinkViewModel) {
        viewModelDidValidatePasswordSuccessfully_Invocations.append(viewModel)

        guard let mock = viewModelDidValidatePasswordSuccessfully_MockMethod else {
            fatalError("no mock for `viewModelDidValidatePasswordSuccessfully`")
        }

        mock(viewModel)
    }

    // MARK: - viewModel

    var viewModelDidFailToValidatePasswordWithReason_Invocations: [(viewModel: CreateSecureGuestLinkViewModel, reason: String)] = []
    var viewModelDidFailToValidatePasswordWithReason_MockMethod: ((CreateSecureGuestLinkViewModel, String) -> Void)?

    func viewModel(_ viewModel: CreateSecureGuestLinkViewModel, didFailToValidatePasswordWithReason reason: String) {
        viewModelDidFailToValidatePasswordWithReason_Invocations.append((viewModel: viewModel, reason: reason))

        guard let mock = viewModelDidFailToValidatePasswordWithReason_MockMethod else {
            fatalError("no mock for `viewModelDidFailToValidatePasswordWithReason`")
        }

        mock(viewModel, reason)
    }

    // MARK: - viewModel

    var viewModelDidCreateLink_Invocations: [(viewModel: CreateSecureGuestLinkViewModel, link: String)] = []
    var viewModelDidCreateLink_MockMethod: ((CreateSecureGuestLinkViewModel, String) -> Void)?

    func viewModel(_ viewModel: CreateSecureGuestLinkViewModel, didCreateLink link: String) {
        viewModelDidCreateLink_Invocations.append((viewModel: viewModel, link: link))

        guard let mock = viewModelDidCreateLink_MockMethod else {
            fatalError("no mock for `viewModelDidCreateLink`")
        }

        mock(viewModel, link)
    }

    // MARK: - viewModel

    var viewModelDidFailToCreateLinkWithError_Invocations: [(viewModel: CreateSecureGuestLinkViewModel, error: Error)] = []
    var viewModelDidFailToCreateLinkWithError_MockMethod: ((CreateSecureGuestLinkViewModel, Error) -> Void)?

    func viewModel(_ viewModel: CreateSecureGuestLinkViewModel, didFailToCreateLinkWithError error: Error) {
        viewModelDidFailToCreateLinkWithError_Invocations.append((viewModel: viewModel, error: error))

        guard let mock = viewModelDidFailToCreateLinkWithError_MockMethod else {
            fatalError("no mock for `viewModelDidFailToCreateLinkWithError`")
        }

        mock(viewModel, error)
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

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
