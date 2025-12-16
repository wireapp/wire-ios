// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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


import CoreLocation
import SwiftUI
import WireDataModel
import WireSyncEngine
import WireAccountImageUI
import WireMessagingDomain
import WireMessagingUI
import WireFoundation

@testable import Wire
@testable import WireCommonComponents
























class MockAccountSelector: AccountSelector {

    // MARK: - Life cycle


    // MARK: - currentAccount

    var currentAccount: Account?


    // MARK: - switchTo

    var switchToAccount_Invocations: [Account] = []
    var switchToAccount_MockMethod: ((Account) -> Void)?

    func switchTo(account: Account) {
        switchToAccount_Invocations.append(account)

        guard let mock = switchToAccount_MockMethod else {
            fatalError("no mock for `switchToAccount`")
        }

        mock(account)
    }

    // MARK: - switchTo

    var switchToAccountCompletion_Invocations: [(account: Account, completion: ((UserSession?) -> Void)?)] = []
    var switchToAccountCompletion_MockMethod: ((Account, ((UserSession?) -> Void)?) -> Void)?

    func switchTo(account: Account, completion: ((UserSession?) -> Void)?) {
        switchToAccountCompletion_Invocations.append((account: account, completion: completion))

        guard let mock = switchToAccountCompletion_MockMethod else {
            fatalError("no mock for `switchToAccountCompletion`")
        }

        mock(account, completion)
    }

}

class MockAppLocationManagerProtocol: AppLocationManagerProtocol {

    // MARK: - Life cycle


    // MARK: - delegate

    var delegate: AppLocationManagerDelegate?

    // MARK: - authorizationStatus

    var authorizationStatus: CLAuthorizationStatus {
        get { return underlyingAuthorizationStatus }
        set(value) { underlyingAuthorizationStatus = value }
    }

    var underlyingAuthorizationStatus: CLAuthorizationStatus!

    // MARK: - userLocationAuthorized

    var userLocationAuthorized: Bool {
        get { return underlyingUserLocationAuthorized }
        set(value) { underlyingUserLocationAuthorized = value }
    }

    var underlyingUserLocationAuthorized: Bool!


    // MARK: - requestLocationAuthorization

    var requestLocationAuthorization_Invocations: [Void] = []
    var requestLocationAuthorization_MockMethod: (() -> Void)?

    func requestLocationAuthorization() {
        requestLocationAuthorization_Invocations.append(())

        guard let mock = requestLocationAuthorization_MockMethod else {
            fatalError("no mock for `requestLocationAuthorization`")
        }

        mock()
    }

    // MARK: - startUpdatingLocation

    var startUpdatingLocation_Invocations: [Void] = []
    var startUpdatingLocation_MockMethod: (() -> Void)?

    func startUpdatingLocation() {
        startUpdatingLocation_Invocations.append(())

        guard let mock = startUpdatingLocation_MockMethod else {
            fatalError("no mock for `startUpdatingLocation`")
        }

        mock()
    }

    // MARK: - stopUpdatingLocation

    var stopUpdatingLocation_Invocations: [Void] = []
    var stopUpdatingLocation_MockMethod: (() -> Void)?

    func stopUpdatingLocation() {
        stopUpdatingLocation_Invocations.append(())

        guard let mock = stopUpdatingLocation_MockMethod else {
            fatalError("no mock for `stopUpdatingLocation`")
        }

        mock()
    }

}

class MockAppStateCalculatorDelegate: AppStateCalculatorDelegate {

    // MARK: - Life cycle



    // MARK: - appStateCalculator

    var appStateCalculatorDidCalculateCompletion_Invocations: [(appStateCalculator: AppStateCalculator, appState: AppState, completion: () -> Void)] = []
    var appStateCalculatorDidCalculateCompletion_MockMethod: ((AppStateCalculator, AppState, @escaping () -> Void) -> Void)?

    func appStateCalculator(_ appStateCalculator: AppStateCalculator, didCalculate appState: AppState, completion: @escaping () -> Void) {
        appStateCalculatorDidCalculateCompletion_Invocations.append((appStateCalculator: appStateCalculator, appState: appState, completion: completion))

        guard let mock = appStateCalculatorDidCalculateCompletion_MockMethod else {
            fatalError("no mock for `appStateCalculatorDidCalculateCompletion`")
        }

        mock(appStateCalculator, appState, completion)
    }

}

class MockCallQualityRouterProtocol: CallQualityRouterProtocol {

    // MARK: - Life cycle



    // MARK: - presentCallQualitySurvey

    var presentCallQualitySurveyWith_Invocations: [TimeInterval] = []
    var presentCallQualitySurveyWith_MockMethod: ((TimeInterval) -> Void)?

    func presentCallQualitySurvey(with callDuration: TimeInterval) {
        presentCallQualitySurveyWith_Invocations.append(callDuration)

        guard let mock = presentCallQualitySurveyWith_MockMethod else {
            fatalError("no mock for `presentCallQualitySurveyWith`")
        }

        mock(callDuration)
    }

    // MARK: - dismissCallQualitySurvey

    var dismissCallQualitySurveyCompletion_Invocations: [Completion?] = []
    var dismissCallQualitySurveyCompletion_MockMethod: ((Completion?) -> Void)?

    func dismissCallQualitySurvey(completion: Completion?) {
        dismissCallQualitySurveyCompletion_Invocations.append(completion)

        guard let mock = dismissCallQualitySurveyCompletion_MockMethod else {
            fatalError("no mock for `dismissCallQualitySurveyCompletion`")
        }

        mock(completion)
    }

    // MARK: - presentCallFailureDebugAlert

    var presentCallFailureDebugAlertMainWindow_Invocations: [UIWindow] = []
    var presentCallFailureDebugAlertMainWindow_MockMethod: ((UIWindow) -> Void)?

    func presentCallFailureDebugAlert(mainWindow: UIWindow) {
        presentCallFailureDebugAlertMainWindow_Invocations.append(mainWindow)

        guard let mock = presentCallFailureDebugAlertMainWindow_MockMethod else {
            fatalError("no mock for `presentCallFailureDebugAlertMainWindow`")
        }

        mock(mainWindow)
    }

    // MARK: - presentCallQualityRejection

    var presentCallQualityRejectionMainWindow_Invocations: [UIWindow] = []
    var presentCallQualityRejectionMainWindow_MockMethod: ((UIWindow) -> Void)?

    func presentCallQualityRejection(mainWindow: UIWindow) {
        presentCallQualityRejectionMainWindow_Invocations.append(mainWindow)

        guard let mock = presentCallQualityRejectionMainWindow_MockMethod else {
            fatalError("no mock for `presentCallQualityRejectionMainWindow`")
        }

        mock(mainWindow)
    }

}

class MockConnectViewControllerBuilderProtocol: ConnectViewControllerBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - build

    var build_Invocations: [Void] = []
    var build_MockMethod: (() async -> UIViewController)?
    var build_MockValue: UIViewController?

    @MainActor
    func build() async -> UIViewController {
        build_Invocations.append(())

        if let mock = build_MockMethod {
            return await mock()
        } else if let mock = build_MockValue {
            return mock
        } else {
            fatalError("no mock for `build`")
        }
    }

}

class MockConversationCellProviderProtocol: ConversationCellProviderProtocol {

    // MARK: - Life cycle



    // MARK: - provideCell

    var provideCellForTableViewIndexPathOnLongPress_Invocations: [(model: ConversationCellModel, tableView: UITableView, indexPath: IndexPath, onLongPress: (UITableViewCell) -> Void)] = []
    var provideCellForTableViewIndexPathOnLongPress_MockMethod: ((ConversationCellModel, UITableView, IndexPath, @escaping (UITableViewCell) -> Void) -> UITableViewCell)?
    var provideCellForTableViewIndexPathOnLongPress_MockValue: UITableViewCell?

    @MainActor
    func provideCell(for model: ConversationCellModel, tableView: UITableView, indexPath: IndexPath, onLongPress: @escaping (UITableViewCell) -> Void) -> UITableViewCell {
        provideCellForTableViewIndexPathOnLongPress_Invocations.append((model: model, tableView: tableView, indexPath: indexPath, onLongPress: onLongPress))

        if let mock = provideCellForTableViewIndexPathOnLongPress_MockMethod {
            return mock(model, tableView, indexPath, onLongPress)
        } else if let mock = provideCellForTableViewIndexPathOnLongPress_MockValue {
            return mock
        } else {
            fatalError("no mock for `provideCellForTableViewIndexPathOnLongPress`")
        }
    }

}

class MockConversationGuestOptionsViewModelDelegate: ConversationGuestOptionsViewModelDelegate {

    // MARK: - Life cycle



    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelDidUpdateState_Invocations: [(viewModel: ConversationGuestOptionsViewModel, state: ConversationGuestOptionsViewModel.State)] = []
    var conversationGuestOptionsViewModelDidUpdateState_MockMethod: ((ConversationGuestOptionsViewModel, ConversationGuestOptionsViewModel.State) -> Void)?

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, didUpdateState state: ConversationGuestOptionsViewModel.State) {
        conversationGuestOptionsViewModelDidUpdateState_Invocations.append((viewModel: viewModel, state: state))

        guard let mock = conversationGuestOptionsViewModelDidUpdateState_MockMethod else {
            fatalError("no mock for `conversationGuestOptionsViewModelDidUpdateState`")
        }

        mock(viewModel, state)
    }

    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelDidReceiveError_Invocations: [(viewModel: ConversationGuestOptionsViewModel, error: Error)] = []
    var conversationGuestOptionsViewModelDidReceiveError_MockMethod: ((ConversationGuestOptionsViewModel, Error) -> Void)?

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, didReceiveError error: Error) {
        conversationGuestOptionsViewModelDidReceiveError_Invocations.append((viewModel: viewModel, error: error))

        guard let mock = conversationGuestOptionsViewModelDidReceiveError_MockMethod else {
            fatalError("no mock for `conversationGuestOptionsViewModelDidReceiveError`")
        }

        mock(viewModel, error)
    }

    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests_Invocations: [(viewModel: ConversationGuestOptionsViewModel, sourceView: UIView, completion: (Bool) -> Void)] = []
    var conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests_MockMethod: ((ConversationGuestOptionsViewModel, UIView, @escaping (Bool) -> Void) -> UIAlertController?)?
    var conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests_MockValue: UIAlertController??

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, sourceView: UIView, confirmRemovingGuests completion: @escaping (Bool) -> Void) -> UIAlertController? {
        conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests_Invocations.append((viewModel: viewModel, sourceView: sourceView, completion: completion))

        if let mock = conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests_MockMethod {
            return mock(viewModel, sourceView, completion)
        } else if let mock = conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationGuestOptionsViewModelSourceViewConfirmRemovingGuests`")
        }
    }

    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_Invocations: [(viewModel: ConversationGuestOptionsViewModel, sourceView: UIView, completion: (GuestLinkType) -> Void)] = []
    var conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_MockMethod: ((ConversationGuestOptionsViewModel, UIView, @escaping (GuestLinkType) -> Void) -> Void)?

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, sourceView: UIView, presentGuestLinkTypeSelection completion: @escaping (GuestLinkType) -> Void) {
        conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_Invocations.append((viewModel: viewModel, sourceView: sourceView, completion: completion))

        guard let mock = conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_MockMethod else {
            fatalError("no mock for `conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection`")
        }

        mock(viewModel, sourceView, completion)
    }

    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelSourceViewConfirmRevokingLink_Invocations: [(viewModel: ConversationGuestOptionsViewModel, sourceView: UIView, completion: (Bool) -> Void)] = []
    var conversationGuestOptionsViewModelSourceViewConfirmRevokingLink_MockMethod: ((ConversationGuestOptionsViewModel, UIView, @escaping (Bool) -> Void) -> Void)?

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, sourceView: UIView, confirmRevokingLink completion: @escaping (Bool) -> Void) {
        conversationGuestOptionsViewModelSourceViewConfirmRevokingLink_Invocations.append((viewModel: viewModel, sourceView: sourceView, completion: completion))

        guard let mock = conversationGuestOptionsViewModelSourceViewConfirmRevokingLink_MockMethod else {
            fatalError("no mock for `conversationGuestOptionsViewModelSourceViewConfirmRevokingLink`")
        }

        mock(viewModel, sourceView, completion)
    }

    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelWantsToShareMessageSourceView_Invocations: [(viewModel: ConversationGuestOptionsViewModel, message: String, sourceView: UIView)] = []
    var conversationGuestOptionsViewModelWantsToShareMessageSourceView_MockMethod: ((ConversationGuestOptionsViewModel, String, UIView) -> Void)?

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, wantsToShareMessage message: String, sourceView: UIView) {
        conversationGuestOptionsViewModelWantsToShareMessageSourceView_Invocations.append((viewModel: viewModel, message: message, sourceView: sourceView))

        guard let mock = conversationGuestOptionsViewModelWantsToShareMessageSourceView_MockMethod else {
            fatalError("no mock for `conversationGuestOptionsViewModelWantsToShareMessageSourceView`")
        }

        mock(viewModel, message, sourceView)
    }

    // MARK: - conversationGuestOptionsViewModel

    var conversationGuestOptionsViewModelPresentCreateSecureGuestLinkAnimated_Invocations: [(viewModel: ConversationGuestOptionsViewModel, viewController: UIViewController, animated: Bool)] = []
    var conversationGuestOptionsViewModelPresentCreateSecureGuestLinkAnimated_MockMethod: ((ConversationGuestOptionsViewModel, UIViewController, Bool) -> Void)?

    func conversationGuestOptionsViewModel(_ viewModel: ConversationGuestOptionsViewModel, presentCreateSecureGuestLink viewController: UIViewController, animated: Bool) {
        conversationGuestOptionsViewModelPresentCreateSecureGuestLinkAnimated_Invocations.append((viewModel: viewModel, viewController: viewController, animated: animated))

        guard let mock = conversationGuestOptionsViewModelPresentCreateSecureGuestLinkAnimated_MockMethod else {
            fatalError("no mock for `conversationGuestOptionsViewModelPresentCreateSecureGuestLinkAnimated`")
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

class MockCreateGroupConversationViewControllerBuilderProtocol: CreateGroupConversationViewControllerBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - build

    var build_Invocations: [Void] = []
    var build_MockMethod: (() async -> UIViewController)?
    var build_MockValue: UIViewController?

    @MainActor
    func build() async -> UIViewController {
        build_Invocations.append(())

        if let mock = build_MockMethod {
            return await mock()
        } else if let mock = build_MockValue {
            return mock
        } else {
            fatalError("no mock for `build`")
        }
    }

}

class MockCreatePasswordSecuredLinkViewModelDelegate: CreatePasswordSecuredLinkViewModelDelegate {

    // MARK: - Life cycle



    // MARK: - viewModel

    var viewModelDidGeneratePassword_Invocations: [(viewModel: CreateSecureConversationGuestLinkViewModel, password: String)] = []
    var viewModelDidGeneratePassword_MockMethod: ((CreateSecureConversationGuestLinkViewModel, String) -> Void)?

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didGeneratePassword password: String) {
        viewModelDidGeneratePassword_Invocations.append((viewModel: viewModel, password: password))

        guard let mock = viewModelDidGeneratePassword_MockMethod else {
            fatalError("no mock for `viewModelDidGeneratePassword`")
        }

        mock(viewModel, password)
    }

    // MARK: - viewModelDidValidatePasswordSuccessfully

    var viewModelDidValidatePasswordSuccessfully_Invocations: [CreateSecureConversationGuestLinkViewModel] = []
    var viewModelDidValidatePasswordSuccessfully_MockMethod: ((CreateSecureConversationGuestLinkViewModel) -> Void)?

    func viewModelDidValidatePasswordSuccessfully(_ viewModel: CreateSecureConversationGuestLinkViewModel) {
        viewModelDidValidatePasswordSuccessfully_Invocations.append(viewModel)

        guard let mock = viewModelDidValidatePasswordSuccessfully_MockMethod else {
            fatalError("no mock for `viewModelDidValidatePasswordSuccessfully`")
        }

        mock(viewModel)
    }

    // MARK: - viewModel

    var viewModelDidFailToValidatePasswordWithReason_Invocations: [(viewModel: CreateSecureConversationGuestLinkViewModel, reason: String)] = []
    var viewModelDidFailToValidatePasswordWithReason_MockMethod: ((CreateSecureConversationGuestLinkViewModel, String) -> Void)?

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didFailToValidatePasswordWithReason reason: String) {
        viewModelDidFailToValidatePasswordWithReason_Invocations.append((viewModel: viewModel, reason: reason))

        guard let mock = viewModelDidFailToValidatePasswordWithReason_MockMethod else {
            fatalError("no mock for `viewModelDidFailToValidatePasswordWithReason`")
        }

        mock(viewModel, reason)
    }

    // MARK: - viewModel

    var viewModelDidCreateLink_Invocations: [(viewModel: CreateSecureConversationGuestLinkViewModel, link: String)] = []
    var viewModelDidCreateLink_MockMethod: ((CreateSecureConversationGuestLinkViewModel, String) -> Void)?

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didCreateLink link: String) {
        viewModelDidCreateLink_Invocations.append((viewModel: viewModel, link: link))

        guard let mock = viewModelDidCreateLink_MockMethod else {
            fatalError("no mock for `viewModelDidCreateLink`")
        }

        mock(viewModel, link)
    }

    // MARK: - viewModel

    var viewModelDidFailToCreateLinkWithError_Invocations: [(viewModel: CreateSecureConversationGuestLinkViewModel, error: Error)] = []
    var viewModelDidFailToCreateLinkWithError_MockMethod: ((CreateSecureConversationGuestLinkViewModel, Error) -> Void)?

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didFailToCreateLinkWithError error: Error) {
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

class MockDidPresentNotificationPermissionHintUseCaseProtocol: DidPresentNotificationPermissionHintUseCaseProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invoke_Invocations: [Void] = []
    var invoke_MockMethod: (() -> Void)?

    func invoke() {
        invoke_Invocations.append(())

        guard let mock = invoke_MockMethod else {
            fatalError("no mock for `invoke`")
        }

        mock()
    }

}

public class MockFileMetaDataGeneratorProtocol: FileMetaDataGeneratorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - metadataForFile

    public var metadataForFileAt_Invocations: [URL] = []
    public var metadataForFileAt_MockMethod: ((URL) async -> ZMFileMetadata)?
    public var metadataForFileAt_MockValue: ZMFileMetadata?

    public func metadataForFile(at url: URL) async -> ZMFileMetadata {
        metadataForFileAt_Invocations.append(url)

        if let mock = metadataForFileAt_MockMethod {
            return await mock(url)
        } else if let mock = metadataForFileAt_MockValue {
            return mock
        } else {
            fatalError("no mock for `metadataForFileAt`")
        }
    }

}

class MockGetParticipantImageSourceRepositoryProtocol: GetParticipantImageSourceRepositoryProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invokeUser_Invocations: [UserType] = []
    var invokeUser_MockMethod: ((UserType) async -> UIImage?)?
    var invokeUser_MockValue: UIImage??

    func invoke(user: UserType) async -> UIImage? {
        invokeUser_Invocations.append(user)

        if let mock = invokeUser_MockMethod {
            return await mock(user)
        } else if let mock = invokeUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUser`")
        }
    }

}

class MockGetParticipantImageSourceUseCaseProtocol: GetParticipantImageSourceUseCaseProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invokeUser_Invocations: [UserType] = []
    var invokeUser_MockMethod: ((UserType) async -> WireAccountImageUI.AccountImageSource?)?
    var invokeUser_MockValue: WireAccountImageUI.AccountImageSource??

    func invoke(user: UserType) async -> WireAccountImageUI.AccountImageSource? {
        invokeUser_Invocations.append(user)

        if let mock = invokeUser_MockMethod {
            return await mock(user)
        } else if let mock = invokeUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUser`")
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

public class MockNetworkStatusObservable: NetworkStatusObservable {

    // MARK: - Life cycle

    public init() {}

    // MARK: - reachability

    public var reachability: ServerReachability {
        get { return underlyingReachability }
        set(value) { underlyingReachability = value }
    }

    public var underlyingReachability: ServerReachability!


}

class MockNetworkStatusViewDelegate: NetworkStatusViewDelegate {

    // MARK: - Life cycle


    // MARK: - shouldAnimateNetworkStatusView

    var shouldAnimateNetworkStatusView: Bool {
        get { return underlyingShouldAnimateNetworkStatusView }
        set(value) { underlyingShouldAnimateNetworkStatusView = value }
    }

    var underlyingShouldAnimateNetworkStatusView: Bool!

    // MARK: - bottomMargin

    var bottomMargin: CGFloat {
        get { return underlyingBottomMargin }
        set(value) { underlyingBottomMargin = value }
    }

    var underlyingBottomMargin: CGFloat!


    // MARK: - didChangeHeight

    var didChangeHeightAnimatedState_Invocations: [(networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState)] = []
    var didChangeHeightAnimatedState_MockMethod: ((NetworkStatusView, Bool, NetworkStatusViewState) -> Void)?

    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState) {
        didChangeHeightAnimatedState_Invocations.append((networkStatusView: networkStatusView, animated: animated, state: state))

        guard let mock = didChangeHeightAnimatedState_MockMethod else {
            fatalError("no mock for `didChangeHeightAnimatedState`")
        }

        mock(networkStatusView, animated, state)
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

class MockSelfProfileAccountManager: SelfProfileAccountManager {

    // MARK: - Life cycle


    // MARK: - selectedAccount

    var selectedAccount: Account?


    // MARK: - sortedAccounts

    var sortedAccounts_Invocations: [Void] = []
    var sortedAccounts_MockMethod: (() -> [Account])?
    var sortedAccounts_MockValue: [Account]?

    func sortedAccounts() -> [Account] {
        sortedAccounts_Invocations.append(())

        if let mock = sortedAccounts_MockMethod {
            return mock()
        } else if let mock = sortedAccounts_MockValue {
            return mock
        } else {
            fatalError("no mock for `sortedAccounts`")
        }
    }

}

class MockSelfProfileViewControllerBuilderProtocol: SelfProfileViewControllerBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - build

    var buildMainCoordinator_Invocations: [AnyMainCoordinator] = []
    var buildMainCoordinator_MockMethod: ((AnyMainCoordinator) -> ViewController)?
    var buildMainCoordinator_MockValue: ViewController?

    @MainActor
    func build(mainCoordinator: AnyMainCoordinator) -> ViewController {
        buildMainCoordinator_Invocations.append(mainCoordinator)

        if let mock = buildMainCoordinator_MockMethod {
            return mock(mainCoordinator)
        } else if let mock = buildMainCoordinator_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildMainCoordinator`")
        }
    }

}

class MockSettingsDebugReportRouterProtocol: SettingsDebugReportRouterProtocol {

    // MARK: - Life cycle



    // MARK: - presentMailComposer

    var presentMailComposer_Invocations: [Void] = []
    var presentMailComposer_MockMethod: (() -> Void)?

    @MainActor
    func presentMailComposer() {
        presentMailComposer_Invocations.append(())

        guard let mock = presentMailComposer_MockMethod else {
            fatalError("no mock for `presentMailComposer`")
        }

        mock()
    }

    // MARK: - presentFallbackAlert

    var presentFallbackAlertSender_Invocations: [UIView] = []
    var presentFallbackAlertSender_MockMethod: ((UIView) -> Void)?

    func presentFallbackAlert(sender: UIView) {
        presentFallbackAlertSender_Invocations.append(sender)

        guard let mock = presentFallbackAlertSender_MockMethod else {
            fatalError("no mock for `presentFallbackAlertSender`")
        }

        mock(sender)
    }

    // MARK: - presentShareViewController

    var presentShareViewControllerDestinationsDebugReport_Invocations: [(destinations: [ZMConversation], debugReport: ShareableDebugReport)] = []
    var presentShareViewControllerDestinationsDebugReport_MockMethod: (([ZMConversation], ShareableDebugReport) -> Void)?

    func presentShareViewController(destinations: [ZMConversation], debugReport: ShareableDebugReport) {
        presentShareViewControllerDestinationsDebugReport_Invocations.append((destinations: destinations, debugReport: debugReport))

        guard let mock = presentShareViewControllerDestinationsDebugReport_MockMethod else {
            fatalError("no mock for `presentShareViewControllerDestinationsDebugReport`")
        }

        mock(destinations, debugReport)
    }

}

class MockSettingsDebugReportViewModelProtocol: SettingsDebugReportViewModelProtocol {

    // MARK: - Life cycle



    // MARK: - sendReport

    var sendReportSender_Invocations: [UIView] = []
    var sendReportSender_MockMethod: ((UIView) -> Void)?

    func sendReport(sender: UIView) {
        sendReportSender_Invocations.append(sender)

        guard let mock = sendReportSender_MockMethod else {
            fatalError("no mock for `sendReportSender`")
        }

        mock(sender)
    }

    // MARK: - shareReport

    var shareReport_Invocations: [Void] = []
    var shareReport_MockMethod: (() async -> Void)?

    func shareReport() async {
        shareReport_Invocations.append(())

        guard let mock = shareReport_MockMethod else {
            fatalError("no mock for `shareReport`")
        }

        await mock()
    }

}

class MockShouldPresentNotificationPermissionHintUseCaseProtocol: ShouldPresentNotificationPermissionHintUseCaseProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invoke_Invocations: [Void] = []
    var invoke_MockMethod: (() async -> Bool)?
    var invoke_MockValue: Bool?

    func invoke() async -> Bool {
        invoke_Invocations.append(())

        if let mock = invoke_MockMethod {
            return await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

class MockTopOverlayPresenting: TopOverlayPresenting {

    // MARK: - Life cycle



    // MARK: - presentTopOverlay

    var presentTopOverlayAnimated_Invocations: [(viewController: UIViewController, animated: Bool)] = []
    var presentTopOverlayAnimated_MockMethod: ((UIViewController, Bool) -> Void)?

    func presentTopOverlay(_ viewController: UIViewController, animated: Bool) {
        presentTopOverlayAnimated_Invocations.append((viewController: viewController, animated: animated))

        guard let mock = presentTopOverlayAnimated_MockMethod else {
            fatalError("no mock for `presentTopOverlayAnimated`")
        }

        mock(viewController, animated)
    }

    // MARK: - dismissTopOverlay

    var dismissTopOverlayAnimated_Invocations: [Bool] = []
    var dismissTopOverlayAnimated_MockMethod: ((Bool) -> Void)?

    func dismissTopOverlay(animated: Bool) {
        dismissTopOverlayAnimated_Invocations.append(animated)

        guard let mock = dismissTopOverlayAnimated_MockMethod else {
            fatalError("no mock for `dismissTopOverlayAnimated`")
        }

        mock(animated)
    }

}

class MockTrackingInterface: TrackingInterface {

    // MARK: - Life cycle


    // MARK: - isAnalyticsTrackingEnabled

    var isAnalyticsTrackingEnabled: Bool {
        get { return underlyingIsAnalyticsTrackingEnabled }
        set(value) { underlyingIsAnalyticsTrackingEnabled = value }
    }

    var underlyingIsAnalyticsTrackingEnabled: Bool!


    // MARK: - isAnalyticsTrackingAvailable

    var isAnalyticsTrackingAvailableFor_Invocations: [String] = []
    var isAnalyticsTrackingAvailableFor_MockMethod: ((String) -> Bool)?
    var isAnalyticsTrackingAvailableFor_MockValue: Bool?

    func isAnalyticsTrackingAvailable(for domain: String) -> Bool {
        isAnalyticsTrackingAvailableFor_Invocations.append(domain)

        if let mock = isAnalyticsTrackingAvailableFor_MockMethod {
            return mock(domain)
        } else if let mock = isAnalyticsTrackingAvailableFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `isAnalyticsTrackingAvailableFor`")
        }
    }

    // MARK: - requestAnalyticsConsent

    var requestAnalyticsConsent_Invocations: [Void] = []
    var requestAnalyticsConsent_MockError: Error?
    var requestAnalyticsConsent_MockMethod: (() async throws -> Bool)?
    var requestAnalyticsConsent_MockValue: Bool?

    func requestAnalyticsConsent() async throws -> Bool {
        requestAnalyticsConsent_Invocations.append(())

        if let error = requestAnalyticsConsent_MockError {
            throw error
        }

        if let mock = requestAnalyticsConsent_MockMethod {
            return try await mock()
        } else if let mock = requestAnalyticsConsent_MockValue {
            return mock
        } else {
            fatalError("no mock for `requestAnalyticsConsent`")
        }
    }

    // MARK: - disableAnalytics

    var disableAnalytics_Invocations: [Void] = []
    var disableAnalytics_MockError: Error?
    var disableAnalytics_MockMethod: (() throws -> Void)?

    func disableAnalytics() throws {
        disableAnalytics_Invocations.append(())

        if let error = disableAnalytics_MockError {
            throw error
        }

        guard let mock = disableAnalytics_MockMethod else {
            fatalError("no mock for `disableAnalytics`")
        }

        try mock()
    }

    // MARK: - enableAnalytics

    var enableAnalytics_Invocations: [Void] = []
    var enableAnalytics_MockError: Error?
    var enableAnalytics_MockMethod: (() async throws -> Void)?

    func enableAnalytics() async throws {
        enableAnalytics_Invocations.append(())

        if let error = enableAnalytics_MockError {
            throw error
        }

        guard let mock = enableAnalytics_MockMethod else {
            fatalError("no mock for `enableAnalytics`")
        }

        try await mock()
    }

}

class MockWireMeetingsFactoryProtocol: WireMeetingsFactoryProtocol {

    // MARK: - Life cycle



    // MARK: - makeMeetingsView

    var makeMeetingsView_Invocations: [Void] = []
    var makeMeetingsView_MockMethod: (() -> UIViewController)?
    var makeMeetingsView_MockValue: UIViewController?

    @MainActor
    func makeMeetingsView() -> UIViewController {
        makeMeetingsView_Invocations.append(())

        if let mock = makeMeetingsView_MockMethod {
            return mock()
        } else if let mock = makeMeetingsView_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeMeetingsView`")
        }
    }

}

class MockWireMessagingFactoryProtocol: WireMessagingFactoryProtocol {

    // MARK: - Life cycle



    // MARK: - makeUploadDraftUseCase

    var makeUploadDraftUseCaseCellName_Invocations: [String] = []
    var makeUploadDraftUseCaseCellName_MockMethod: ((String) -> WireCellsUploadDraftUseCaseProtocol)?
    var makeUploadDraftUseCaseCellName_MockValue: WireCellsUploadDraftUseCaseProtocol?

    func makeUploadDraftUseCase(cellName: String) -> WireCellsUploadDraftUseCaseProtocol {
        makeUploadDraftUseCaseCellName_Invocations.append(cellName)

        if let mock = makeUploadDraftUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeUploadDraftUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeUploadDraftUseCaseCellName`")
        }
    }

    // MARK: - makeObserveDraftsUseCase

    var makeObserveDraftsUseCaseCellName_Invocations: [String] = []
    var makeObserveDraftsUseCaseCellName_MockMethod: ((String) -> WireCellsObserveDraftsUseCaseProtocol)?
    var makeObserveDraftsUseCaseCellName_MockValue: WireCellsObserveDraftsUseCaseProtocol?

    func makeObserveDraftsUseCase(cellName: String) -> WireCellsObserveDraftsUseCaseProtocol {
        makeObserveDraftsUseCaseCellName_Invocations.append(cellName)

        if let mock = makeObserveDraftsUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeObserveDraftsUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeObserveDraftsUseCaseCellName`")
        }
    }

    // MARK: - makePublishDraftsUseCase

    var makePublishDraftsUseCaseCellName_Invocations: [String] = []
    var makePublishDraftsUseCaseCellName_MockMethod: ((String) -> WireCellsPublishDraftsUseCaseProtocol)?
    var makePublishDraftsUseCaseCellName_MockValue: WireCellsPublishDraftsUseCaseProtocol?

    func makePublishDraftsUseCase(cellName: String) -> WireCellsPublishDraftsUseCaseProtocol {
        makePublishDraftsUseCaseCellName_Invocations.append(cellName)

        if let mock = makePublishDraftsUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makePublishDraftsUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makePublishDraftsUseCaseCellName`")
        }
    }

    // MARK: - makeClearPublishedDraftsUseCase

    var makeClearPublishedDraftsUseCaseCellName_Invocations: [String] = []
    var makeClearPublishedDraftsUseCaseCellName_MockMethod: ((String) -> WireCellsClearPublishedDraftsUseCaseProtocol)?
    var makeClearPublishedDraftsUseCaseCellName_MockValue: WireCellsClearPublishedDraftsUseCaseProtocol?

    func makeClearPublishedDraftsUseCase(cellName: String) -> WireCellsClearPublishedDraftsUseCaseProtocol {
        makeClearPublishedDraftsUseCaseCellName_Invocations.append(cellName)

        if let mock = makeClearPublishedDraftsUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeClearPublishedDraftsUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeClearPublishedDraftsUseCaseCellName`")
        }
    }

    // MARK: - makeDeleteDraftUseCase

    var makeDeleteDraftUseCaseCellName_Invocations: [String] = []
    var makeDeleteDraftUseCaseCellName_MockMethod: ((String) -> WireCellsDeleteDraftUseCaseProtocol)?
    var makeDeleteDraftUseCaseCellName_MockValue: WireCellsDeleteDraftUseCaseProtocol?

    func makeDeleteDraftUseCase(cellName: String) -> WireCellsDeleteDraftUseCaseProtocol {
        makeDeleteDraftUseCaseCellName_Invocations.append(cellName)

        if let mock = makeDeleteDraftUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeDeleteDraftUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeDeleteDraftUseCaseCellName`")
        }
    }

    // MARK: - makeRetryUploadDraftUseCase

    var makeRetryUploadDraftUseCaseCellName_Invocations: [String] = []
    var makeRetryUploadDraftUseCaseCellName_MockMethod: ((String) -> WireCellsRetryUploadDraftUseCaseProtocol)?
    var makeRetryUploadDraftUseCaseCellName_MockValue: WireCellsRetryUploadDraftUseCaseProtocol?

    func makeRetryUploadDraftUseCase(cellName: String) -> WireCellsRetryUploadDraftUseCaseProtocol {
        makeRetryUploadDraftUseCaseCellName_Invocations.append(cellName)

        if let mock = makeRetryUploadDraftUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeRetryUploadDraftUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeRetryUploadDraftUseCaseCellName`")
        }
    }

    // MARK: - makeDeleteNodesUseCase

    var makeDeleteNodesUseCase_Invocations: [Void] = []
    var makeDeleteNodesUseCase_MockMethod: (() -> WireCellsDeleteNodesUseCaseProtocol)?
    var makeDeleteNodesUseCase_MockValue: WireCellsDeleteNodesUseCaseProtocol?

    func makeDeleteNodesUseCase() -> WireCellsDeleteNodesUseCaseProtocol {
        makeDeleteNodesUseCase_Invocations.append(())

        if let mock = makeDeleteNodesUseCase_MockMethod {
            return mock()
        } else if let mock = makeDeleteNodesUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeDeleteNodesUseCase`")
        }
    }

    // MARK: - makeFetchNodeUseCase

    var makeFetchNodeUseCase_Invocations: [Void] = []
    var makeFetchNodeUseCase_MockMethod: (() -> WireCellsFetchNodeUseCaseProtocol)?
    var makeFetchNodeUseCase_MockValue: WireCellsFetchNodeUseCaseProtocol?

    func makeFetchNodeUseCase() -> WireCellsFetchNodeUseCaseProtocol {
        makeFetchNodeUseCase_Invocations.append(())

        if let mock = makeFetchNodeUseCase_MockMethod {
            return mock()
        } else if let mock = makeFetchNodeUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeFetchNodeUseCase`")
        }
    }

    // MARK: - makeFilesView

    var makeFilesViewCellNameIsCellsStatePendingAccentColorProvider_Invocations: [(cellName: String, isCellsStatePending: Bool, accentColorProvider: () -> WireAccentColor)] = []
    var makeFilesViewCellNameIsCellsStatePendingAccentColorProvider_MockMethod: ((String, Bool, @escaping () -> WireAccentColor) -> UIViewController)?
    var makeFilesViewCellNameIsCellsStatePendingAccentColorProvider_MockValue: UIViewController?

    @MainActor
    func makeFilesView(cellName: String, isCellsStatePending: Bool, accentColorProvider: @escaping () -> WireAccentColor) -> UIViewController {
        makeFilesViewCellNameIsCellsStatePendingAccentColorProvider_Invocations.append((cellName: cellName, isCellsStatePending: isCellsStatePending, accentColorProvider: accentColorProvider))

        if let mock = makeFilesViewCellNameIsCellsStatePendingAccentColorProvider_MockMethod {
            return mock(cellName, isCellsStatePending, accentColorProvider)
        } else if let mock = makeFilesViewCellNameIsCellsStatePendingAccentColorProvider_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeFilesViewCellNameIsCellsStatePendingAccentColorProvider`")
        }
    }

    // MARK: - makeFilesBrowserView

    var makeFilesBrowserViewAccentColorProvider_Invocations: [() -> WireAccentColor] = []
    var makeFilesBrowserViewAccentColorProvider_MockMethod: ((@escaping () -> WireAccentColor) -> UIViewController)?
    var makeFilesBrowserViewAccentColorProvider_MockValue: UIViewController?

    @MainActor
    func makeFilesBrowserView(accentColorProvider: @escaping () -> WireAccentColor) -> UIViewController {
        makeFilesBrowserViewAccentColorProvider_Invocations.append(accentColorProvider)

        if let mock = makeFilesBrowserViewAccentColorProvider_MockMethod {
            return mock(accentColorProvider)
        } else if let mock = makeFilesBrowserViewAccentColorProvider_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeFilesBrowserViewAccentColorProvider`")
        }
    }

    // MARK: - makeConversationCellProvider

    var makeConversationCellProviderInsetsProvider_Invocations: [() -> ConversationCellInsets] = []
    var makeConversationCellProviderInsetsProvider_MockMethod: ((@escaping () -> ConversationCellInsets) -> ConversationCellProviderProtocol)?
    var makeConversationCellProviderInsetsProvider_MockValue: ConversationCellProviderProtocol?

    func makeConversationCellProvider(insetsProvider: @escaping () -> ConversationCellInsets) -> ConversationCellProviderProtocol {
        makeConversationCellProviderInsetsProvider_Invocations.append(insetsProvider)

        if let mock = makeConversationCellProviderInsetsProvider_MockMethod {
            return mock(insetsProvider)
        } else if let mock = makeConversationCellProviderInsetsProvider_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeConversationCellProviderInsetsProvider`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
