// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

@testable import Wire

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

}
// swiftlint:enable variable_name
